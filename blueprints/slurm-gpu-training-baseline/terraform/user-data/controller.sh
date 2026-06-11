#!/usr/bin/env bash
set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive

hostnamectl set-hostname slurm-controller

cat >/etc/hosts <<EOF
127.0.0.1 localhost
127.0.1.1 slurm-controller
${worker_private_ip} ${worker_name}
EOF

apt-get update
apt-get install -y \
  munge \
  slurm-wlm \
  nfs-kernel-server \
  jq \
  htop \
  tree

systemctl stop munge || true
rm -f /etc/munge/munge.key

install -d -m 0700 -o munge -g munge /etc/munge
printf '%s' '${munge_key}' >/etc/munge/munge.key
chown munge:munge /etc/munge/munge.key
chmod 0400 /etc/munge/munge.key

systemctl enable --now munge
systemctl restart munge

# Prepare shared EBS volume. The volume is attached after instance creation,
# so wait for it to appear.
for dev in /dev/nvme1n1 /dev/xvdf /dev/sdf; do
  for i in $(seq 1 60); do
    if [ -b "$dev" ]; then
      SHARED_DEV="$dev"
      break 2
    fi
    sleep 2
  done
done

if [ -z "$${SHARED_DEV:-}" ]; then
  echo "Shared EBS device was not found" >&2
  lsblk
  exit 1
fi

if ! blkid "$SHARED_DEV"; then
  mkfs.ext4 -F "$SHARED_DEV"
fi

mkdir -p /shared
if ! grep -q ' /shared ' /etc/fstab; then
  UUID=$(blkid -s UUID -o value "$SHARED_DEV")
  echo "UUID=$UUID /shared ext4 defaults,nofail 0 2" >>/etc/fstab
fi
mount -a

mkdir -p /shared/slurm /shared/ddp
chown -R ubuntu:ubuntu /shared

cat >/etc/exports <<EOF
/shared ${vpc_cidr}(rw,sync,no_subtree_check,no_root_squash)
EOF
exportfs -ra
systemctl enable --now nfs-kernel-server

mkdir -p /etc/slurm /var/spool/slurmctld /var/log/slurm
chown -R slurm:slurm /var/spool/slurmctld /var/log/slurm || true

cat >/etc/slurm/slurm.conf <<EOF
ClusterName=${cluster_name}
SlurmctldHost=slurm-controller
MpiDefault=none
ProctrackType=proctrack/linuxproc
ReturnToService=2
SlurmctldPidFile=/run/slurmctld.pid
SlurmdPidFile=/run/slurmd.pid
SlurmdSpoolDir=/var/spool/slurmd
StateSaveLocation=/var/spool/slurmctld
SwitchType=switch/none
TaskPlugin=task/none
InactiveLimit=0
KillWait=30
MinJobAge=300
SlurmctldTimeout=120
SlurmdTimeout=300
Waittime=0
SchedulerType=sched/backfill
SelectType=select/cons_tres
SelectTypeParameters=CR_Core
AccountingStorageType=accounting_storage/none
JobCompType=jobcomp/none
SlurmctldDebug=info
SlurmctldLogFile=/var/log/slurm/slurmctld.log
SlurmdDebug=info
SlurmdLogFile=/var/log/slurm/slurmd.log

GresTypes=gpu
NodeName=${worker_name} CPUs=${worker_cpus} RealMemory=${worker_real_memory} Gres=gpu:${worker_gpu_count} State=UNKNOWN
PartitionName=gpu Nodes=${worker_name} Default=YES MaxTime=INFINITE State=UP
EOF

cp /etc/slurm/slurm.conf /shared/slurm/slurm.conf
chown -R ubuntu:ubuntu /shared/slurm

systemctl enable --now slurmctld

cat >/shared/ddp/ddp_smoke.py <<'PY'
import os
import socket
import torch
import torch.distributed as dist

def main():
    dist.init_process_group(backend="nccl")
    rank = dist.get_rank()
    world_size = dist.get_world_size()
    local_rank = int(os.environ.get("LOCAL_RANK", "0"))

    torch.cuda.set_device(local_rank)
    x = torch.ones(1, device="cuda") * (rank + 1)
    dist.all_reduce(x)

    print(
        f"host={socket.gethostname()} rank={rank}/{world_size} "
        f"local_rank={local_rank} cuda={torch.cuda.get_device_name(local_rank)} "
        f"all_reduce={x.item()}"
    )

    dist.destroy_process_group()

if __name__ == "__main__":
    main()
PY

cat >/shared/ddp/run_ddp_2node.sbatch <<'SBATCH'
#!/bin/bash
#SBATCH -J ddp-smoke
#SBATCH -p gpu
#SBATCH -N 1
#SBATCH --ntasks-per-node=1
#SBATCH --gres=gpu:1
#SBATCH -o /shared/ddp/ddp-%j.out

set -euxo pipefail

MASTER_ADDR=$(scontrol show hostnames "$SLURM_JOB_NODELIST" | head -n1)
MASTER_PORT=29500
export MASTER_ADDR MASTER_PORT
export NCCL_DEBUG=INFO
export NCCL_SOCKET_IFNAME=ens5,eth0
export OMP_NUM_THREADS=1

cd /shared/ddp

# DLAMI usually ships framework-specific envs. This is intentionally best-effort.
if [ -f /opt/conda/etc/profile.d/conda.sh ]; then
  source /opt/conda/etc/profile.d/conda.sh || true
  conda activate pytorch || true
fi

srun python3 ddp_smoke.py
SBATCH

chown -R ubuntu:ubuntu /shared/ddp

echo "Controller setup completed at $(date -Is)" >/var/log/slurm-controller-user-data.done
