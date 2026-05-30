# Slurm GPU Training Baseline

This blueprint demonstrates a minimal single-node Slurm installation on a local VM.

**Goal:**
- Understand Slurm architecture (controller, compute node, partition, job queue)
- Run basic sbatch and srun jobs
- Prepare for AI GPU training workflows
- Serve as baseline for Slurm vs Kubernetes comparison

**Structure:**
- `docs/`: Setup, commands, and architecture explanations
- `jobs/`: Example batch scripts
- `scripts/`: Utility scripts to check Slurm status

**Next steps:**
- Add GPU/GRES node onboarding
- Integrate PyTorch DDP minimal demo
- Compare Slurm scheduling vs Kubernetes scheduling