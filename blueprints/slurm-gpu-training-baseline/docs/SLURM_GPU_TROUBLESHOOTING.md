# Slurm GPU Troubleshooting

This document lists common issues when adding GPU nodes to Slurm.

## Node Stays DOWN

Check service status:

```bash
sudo systemctl status slurmd --no-pager
sudo journalctl -u slurmd -n 100 --no-pager
```

Common causes:

```text
- Hostname mismatch between slurm.conf and actual hostname
- slurmd cannot reach controller
- Munge authentication failure
- slurm.conf mismatch between controller and compute node
```

## Munge Authentication Failure

Test locally:

```bash
munge -n | unmunge
```

Test across nodes:

```bash
munge -n | ssh <node> unmunge
```

Check:

```text
- /etc/munge/munge.key is identical on all Slurm nodes
- File owner is munge:munge
- File mode is 400
- munge service is active
```

## GPU Not Detected by Slurm

Check OS visibility first:

```bash
nvidia-smi
ls -l /dev/nvidia*
```

Check Slurm GRES configuration:

```bash
cat /etc/slurm/gres.conf
scontrol show node <node-name>
```

Common causes:

```text
- Missing GresTypes=gpu in slurm.conf
- NodeName Gres count missing in slurm.conf
- Wrong File path in gres.conf
- slurmd not restarted after config changes
```

## Job Pending

Check job reason:

```bash
squeue
scontrol show job <job-id>
```

Common reasons:

```text
- Requested GPU count is higher than available
- Wrong partition
- Node is DOWN, DRAIN, or not in the partition
- Time limit exceeds partition limit
```

## PyTorch Cannot See CUDA

Inside the Slurm job, check:

```bash
echo $CUDA_VISIBLE_DEVICES
nvidia-smi
python - <<'PY'
import torch
print(torch.cuda.is_available())
print(torch.cuda.device_count())
PY
```

Common causes:

```text
- PyTorch installed without CUDA support
- Driver/runtime mismatch
- Job did not actually request GPU
- CUDA_VISIBLE_DEVICES is empty
```

## Multi-node DDP / NCCL Issues

Common areas to check:

```text
- Network interface used by NCCL
- Firewall between nodes
- Driver and CUDA compatibility
- Same PyTorch/CUDA versions on all nodes
- DNS or hostname resolution
- MASTER_ADDR and MASTER_PORT
- NCCL_DEBUG=INFO logs
```
