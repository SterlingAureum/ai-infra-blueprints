#!/bin/bash
#SBATCH --job-name=array-demo
#SBATCH --partition=debug
#SBATCH --array=1-5
#SBATCH --time=00:05:00
#SBATCH --output=array-demo-%A-%a.out

echo "Array job id: $SLURM_ARRAY_JOB_ID"
echo "Task id: $SLURM_ARRAY_TASK_ID"
echo "Node: $(hostname)"
sleep $SLURM_ARRAY_TASK_ID
echo "Task $SLURM_ARRAY_TASK_ID done"
