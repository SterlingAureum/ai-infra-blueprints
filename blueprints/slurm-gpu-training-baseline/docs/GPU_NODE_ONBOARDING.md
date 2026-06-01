# GPU Node Onboarding

This document describes the planned GPU node onboarding process for extending the local Slurm baseline toward GPU training workloads.

The current repository phase may not include a real GPU node yet. This document is intended as a production-style checklist and configuration guide for the next GPU-enabled iteration.

## Goal

```text
Add GPU-capable compute nodes to Slurm and allow users to request GPUs through sbatch or srun.
```

## High-level Flow

```text
1. Prepare OS and hostname.
2. Install NVIDIA driver.
3. Validate nvidia-smi.
4. Install CUDA runtime or use CUDA containers.
5. Install Slurm and Munge.
6. Sync Munge key from controller to compute nodes.
7. Configure slurm.conf with GresTypes and GPU resources.
8. Configure gres.conf on GPU nodes.
9. Restart slurmd.
10. Validate GPU visibility through Slurm.
11. Submit a GPU test job.
```

## GPU Node Requirements

```text
OS: Ubuntu 22.04 LTS or similar
NVIDIA driver: Installed and compatible with CUDA runtime
Slurm: Same major version as controller
Munge: Enabled and using the same munge.key as controller
Network: Controller and compute nodes can resolve each other by hostname
Firewall: Slurm ports are reachable between nodes
```

## Basic GPU Validation

Run on the GPU node:

```bash
nvidia-smi
```

Expected result:

```text
The command should show GPU model, driver version, memory, and utilization.
```

## Munge Validation

Run on the controller:

```bash
munge -n | ssh <gpu-node> unmunge
```

Expected result:

```text
STATUS: Success (0)
```

If this fails, Slurm node registration and job launch may fail.

## Slurm GPU Configuration

Slurm usually exposes GPUs through GRES.

In `slurm.conf`:

```text
GresTypes=gpu
```

Example single-GPU node:

```text
NodeName=slurm-gpu-01 CPUs=16 RealMemory=64000 Gres=gpu:1 State=UNKNOWN
PartitionName=gpu Nodes=slurm-gpu-01 Default=NO MaxTime=04:00:00 State=UP
```

Example four-GPU node:

```text
NodeName=slurm-gpu-01 CPUs=32 RealMemory=128000 Gres=gpu:4 State=UNKNOWN
PartitionName=gpu Nodes=slurm-gpu-01 Default=NO MaxTime=04:00:00 State=UP
```

In `/etc/slurm/gres.conf` on the GPU node:

```text
NodeName=slurm-gpu-01 Name=gpu File=/dev/nvidia0
```

For four GPUs:

```text
NodeName=slurm-gpu-01 Name=gpu File=/dev/nvidia0
NodeName=slurm-gpu-01 Name=gpu File=/dev/nvidia1
NodeName=slurm-gpu-01 Name=gpu File=/dev/nvidia2
NodeName=slurm-gpu-01 Name=gpu File=/dev/nvidia3
```

## Restart Slurm Services

On controller:

```bash
sudo systemctl restart slurmctld
```

On GPU node:

```bash
sudo systemctl restart slurmd
```

## Validate GPU Node in Slurm

```bash
sinfo
scontrol show node slurm-gpu-01
```

Look for:

```text
Gres=gpu:<count>
State=IDLE
```

## Submit GPU Job

```bash
sbatch jobs/gpu-check.sbatch
```

The job should print:

```text
CUDA_VISIBLE_DEVICES
nvidia-smi output
PyTorch CUDA availability
```

## Troubleshooting Checklist

| Symptom | Possible Cause | Check |
|---|---|---|
| Node is DOWN | slurmd not running or hostname mismatch | `systemctl status slurmd` |
| Munge auth failed | munge.key mismatch | `munge -n \| unmunge` |
| GPU not visible | missing gres.conf or wrong device path | `/etc/slurm/gres.conf` |
| Job pending | partition or GRES mismatch | `squeue`, `scontrol show job <id>` |
| CUDA not available | driver/runtime/PyTorch mismatch | `nvidia-smi`, `python -c 'import torch'` |
| NCCL error | network, interface, firewall, driver mismatch | NCCL env vars and logs |

## Interview Talking Point

```text
In Slurm, GPU scheduling is usually configured through GRES. The controller needs to know how many GPUs a node has, and each GPU node needs a matching gres.conf that maps logical GPU resources to device files such as /dev/nvidia0. Jobs can then request GPUs with --gres=gpu:1 or similar options.
```

This is different from Kubernetes, where GPUs are usually exposed through the NVIDIA device plugin and consumed through container resource limits.
