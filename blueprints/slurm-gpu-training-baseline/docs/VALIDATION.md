# Validation

## Tested Jobs

| Job | Purpose | Status |
|---|---|---|
| hello-slurm.sbatch | Basic sbatch job submission | Passed |
| array-demo.sbatch | Slurm job array test | Passed |

## Commands Used

```bash
sinfo
squeue
srun hostname
sbatch jobs/hello-slurm.sbatch
sbatch jobs/array-demo.sbatch
```

## Expected Result

- Node is visible in `sinfo`
- Jobs can be submitted through `sbatch`
- Job outputs are generated correctly
- Array jobs create multiple task outputs

## Current Scope

This baseline is CPU-only and runs on a single local VM. It is used to validate the core Slurm workflow before extending to GPU scheduling and distributed training.
