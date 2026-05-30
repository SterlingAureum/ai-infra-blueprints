# Slurm vs Kubernetes for GPU Workloads

| Feature                | Slurm                          | Kubernetes                   |
|------------------------|-------------------------------|-------------------------------|
| Focus                  | HPC batch / GPU training       | Containerized microservices   |
| Scheduling             | Node + partition + backfill   | Pod + Node + scheduler         |
| Job Types              | sbatch / srun                  | Pods, Jobs, CronJobs           |
| GPU Support            | GRES / GPU count per node      | Device Plugins, Limits         |
| Resource Accounting    | cgroup, accounting             | ResourceQuota, Limits, Requests|
| Ideal For              | Large model training, MPI      | Service orchestration, CI/CD  |
| Integration Effort     | Medium                        | Medium-High                   |

> Use a single-node Slurm demo to showcase HPC job workflow, partition, job queue, and resource allocation.