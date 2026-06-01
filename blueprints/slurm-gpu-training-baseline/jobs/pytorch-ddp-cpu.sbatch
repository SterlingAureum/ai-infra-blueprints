#!/bin/bash
#SBATCH --job-name=pytorch-ddp-cpu
#SBATCH --partition=debug
#SBATCH --nodes=1
#SBATCH --ntasks=2
#SBATCH --cpus-per-task=1
#SBATCH --time=00:10:00
#SBATCH --output=pytorch-ddp-cpu-%j.out

set -euo pipefail

echo "Job ID: ${SLURM_JOB_ID}"
echo "Node list: ${SLURM_JOB_NODELIST}"
echo "Number of tasks: ${SLURM_NTASKS}"

export MASTER_ADDR=$(scontrol show hostnames "$SLURM_JOB_NODELIST" | head -n 1)
export MASTER_PORT=29500
export WORLD_SIZE=${SLURM_NTASKS}

echo "MASTER_ADDR=${MASTER_ADDR}"
echo "MASTER_PORT=${MASTER_PORT}"
echo "WORLD_SIZE=${WORLD_SIZE}"

srun python3 examples/pytorch_ddp_cpu.py
