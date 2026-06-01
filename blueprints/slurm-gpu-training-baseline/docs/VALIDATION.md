# Validation

This document records the Slurm jobs and workflows that have been validated in the local single-node VM environment.

The current baseline is CPU-only and runs on a single local VM. It validates the core Slurm workflow and a minimal PyTorch distributed communication demo before extending to GPU scheduling and multi-node training.

## Tested Environment

```text
Mode: Local single-node Slurm baseline
Node role: controller + compute node on the same VM
GPU: Not used in this phase
Slurm services: slurmctld + slurmd
Authentication: Munge
PyTorch backend: gloo
Distributed mode: single-node, multi-process
```

## Tested Jobs

| Job | Purpose | Status |
|---|---|---|
| hello-slurm.sbatch | Basic sbatch job submission | Passed |
| array-demo.sbatch | Slurm job array test | Passed |
| `pytorch-ddp-cpu.sbatch` | CPU-based PyTorch distributed communication demo | Passed |

## Commands Used

```bash
sinfo
squeue
srun hostname
sbatch jobs/hello-slurm.sbatch
sbatch jobs/array-demo.sbatch
sbatch jobs/pytorch-ddp-cpu.sbatch
```

## Validated:

```text
- Local single-node Slurm installation
- Munge-based Slurm authentication
- Basic sbatch workflow
- Slurm array job
- srun command execution
- CPU-based PyTorch distributed communication
- 2-task Slurm launch
- gloo backend initialization
- rank/world_size environment
- all_reduce communication
```

## Status Summary

Current phase: CPU distributed training demo validated
Next phase: Single-node GPU Slurm GRES validation
