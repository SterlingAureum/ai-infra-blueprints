# Slurm Basic Commands

- Check nodes: `sinfo`  
- Show node details: `scontrol show nodes`  
- Check queue: `squeue`  
- Submit job: `sbatch hello-slurm.sbatch`  
- Run inline job: `srun hostname`  
- Cancel job: `scancel <jobid>`  
- Check Slurm services:
```bash
systemctl status slurmctld
systemctl status slurmd
systemctl status munge
```

- Example array job: `sbatch array-demo.sbatch`
