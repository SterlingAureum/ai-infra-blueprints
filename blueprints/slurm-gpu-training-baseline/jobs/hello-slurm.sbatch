#!/bin/bash
#SBATCH --job-name=hello-slurm
#SBATCH --partition=debug
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=00:05:00
#SBATCH --output=hello-slurm-%j.out

echo "Job ID: $SLURM_JOB_ID"
echo "Node: $(hostname)"
echo "User: $(whoami)"
echo "Working dir: $(pwd)"
echo "CPU count: $(nproc)"
date
sleep 5
echo "Done"
