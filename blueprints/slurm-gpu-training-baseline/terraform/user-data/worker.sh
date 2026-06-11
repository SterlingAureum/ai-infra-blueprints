#!/usr/bin/env bash
set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive

hostnamectl set-hostname ${worker_name}

cat >/etc/hosts <<EOF
127.0.0.1 localhost
127.0.1.1 ${worker_name}
${controller_private_ip} ${controller_name}
EOF

apt-get update
apt-get install -y \
  munge \
  slurm-wlm \
  nfs-common \
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

mkdir -p /shared
for i in $(seq 1 120); do
  if mount -t nfs ${controller_private_ip}:/shared /shared; then
    break
  fi
  sleep 5
done

if ! mountpoint -q /shared; then
  echo "Failed to mount /shared from controller" >&2
  exit 1
fi

if ! grep -q ' /shared ' /etc/fstab; then
  echo "${controller_private_ip}:/shared /shared nfs defaults,_netdev 0 0" >>/etc/fstab
fi

mkdir -p /etc/slurm /var/spool/slurmd /var/log/slurm
chown -R slurm:slurm /var/spool/slurmd /var/log/slurm || true

# Wait for controller to write the canonical Slurm config.
for i in $(seq 1 120); do
  if [ -f /shared/slurm/slurm.conf ]; then
    cp /shared/slurm/slurm.conf /etc/slurm/slurm.conf
    break
  fi
  sleep 5
done

if [ ! -f /etc/slurm/slurm.conf ]; then
  echo "Missing /shared/slurm/slurm.conf" >&2
  exit 1
fi

# Configure GPU GRES. DLAMI should already have NVIDIA driver/NVML.
if [ "${worker_gpu_count}" = "1" ]; then
  GPU_FILE="/dev/nvidia0"
else
  LAST_GPU=$(( ${worker_gpu_count} - 1 ))
  GPU_FILE="/dev/nvidia[0-$${LAST_GPU}]"
fi

cat >/etc/slurm/gres.conf <<EOF
NodeName=${worker_name} Name=gpu File=$${GPU_FILE}
EOF

# Wait for NVIDIA driver to be ready. Do not fail immediately because DLAMI can initialize slowly.
for i in $(seq 1 60); do
  if command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi; then
    break
  fi
  sleep 5
done

systemctl enable --now slurmd

echo "Worker setup completed at $(date -Is)" >/var/log/slurm-worker-user-data.done
