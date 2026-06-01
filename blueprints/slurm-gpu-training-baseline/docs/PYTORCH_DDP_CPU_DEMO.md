# PyTorch DDP CPU Demo

This document describes a minimal PyTorch Distributed Data Parallel style demo launched by Slurm on CPU.

The goal is not to train a real model. The goal is to validate how Slurm launches multiple tasks and how PyTorch distributed processes discover each other.

## Why CPU DDP First

```text
1. It does not require GPU rental.
2. It validates Slurm multi-task launch behavior.
3. It introduces rank, world size, master address, and master port.
4. It prepares the repository for future GPU DDP and NCCL examples.
```

## Files

```text
examples/pytorch_ddp_cpu.py
jobs/pytorch-ddp-cpu.sbatch
```

## Install PyTorch

For a CPU-only VM, install the CPU PyTorch package.

```bash
sudo apt update
sudo apt install -y python3.10-venv python3-pip
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install torch --index-url https://download.pytorch.org/whl/cpu
pip install numpy
```

Validate:

```bash
python - <<'PY'
import torch
print(torch.__version__)
print(torch.cuda.is_available())
PY
```

## Run with Slurm

```bash
sbatch jobs/pytorch-ddp-cpu.sbatch
```

Check queue:

```bash
squeue
```

Check output:

```bash
cat pytorch-ddp-cpu-*.out
```

## Expected Output

Each Slurm task should print:

```text
rank
world size
hostname
backend
a simple all_reduce result
```

For a 2-task job, the all_reduce result should confirm that processes communicated with each other.

## Notes

This demo uses the `gloo` backend because it runs on CPU.

Future GPU DDP examples should use:

```text
backend: nccl
GPU request: --gres=gpu:<count>
CUDA_VISIBLE_DEVICES
NCCL environment variables if needed
```

