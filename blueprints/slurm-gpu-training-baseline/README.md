# AWS Slurm GPU Training Baseline

A minimal Terraform-based Slurm GPU lab on AWS.

This demo creates a small Slurm cluster for AI infrastructure learning, GPU scheduling validation, and future distributed training experiments.

## What This Demo Creates

- 1 Slurm controller node
- 1 GPU worker node
- AWS VPC, subnet, route table, security groups
- Munge authentication
- Slurm controller and worker services
- NFS shared directory mounted at `/shared`
- GPU GRES configuration
- Basic Slurm GPU validation workflow

## Architecture

```text
User
  |
  | SSH
  v
Slurm Controller
  - slurmctld
  - munge
  - NFS server
  - /shared
  |
  | Slurm control + NFS
  v
GPU Worker
  - slurmd
  - munge
  - NVIDIA GPU
  - /shared mounted from controller
```

## Configure Variables

Copy the example file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit:

```bash
nano terraform.tfvars
```

Required values:

```hcl
ssh_key_name    = "your-ec2-key-pair-name"
allowed_ssh_cidr = "your-public-ip/32"
```

Example:

```hcl
ssh_key_name     = "slurm-lab-key"
allowed_ssh_cidr = "1.2.3.4/32"
```

## Deploy

Initialize Terraform:

```bash
terraform init
```

Validate:

```bash
terraform validate
```

Apply:

```bash
terraform apply
```

Or for local testing:

```bash
terraform apply -auto-approve
```

## SSH Into Controller

After deployment, get the controller public IP from Terraform output.

Example:

```bash
ssh -i ~/.ssh/slurm-lab-key.pem ubuntu@<controller-public-ip>
```

## Validate Slurm

On the controller node:

```bash
sinfo
```

Expected result:

```text
PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
gpu*         up   infinite      1   idle  slurm-gpu-1
```

Check node details:

```bash
scontrol show node slurm-gpu-1
```

Run a basic Slurm job:

```bash
srun -p gpu -N1 -n1 hostname
```

Expected result:

```text
slurm-gpu-1
```

Validate GPU access:

```bash
srun -p gpu -N1 -n1 nvidia-smi
```

Validate GPU GRES allocation:

```bash
srun -p gpu -N1 -n1 --gres=gpu:1 bash -lc 'hostname && nvidia-smi -L'
```

## Useful Logs

Controller:

```bash
sudo systemctl status slurmctld --no-pager
sudo tail -n 100 /var/log/slurm/slurmctld.log
```

Worker:

```bash
sudo systemctl status slurmd --no-pager
sudo tail -n 100 /var/log/slurm/slurmd.log
```

Munge:

```bash
sudo systemctl status munge --no-pager
munge -n | unmunge
```

## Common Issues

### Node Shows UNKNOWN or NOT_RESPONDING

Check the worker service:

```bash
sudo systemctl status slurmd --no-pager
sudo tail -n 100 /var/log/slurm/slurmd.log
```

Check from controller:

```bash
scontrol show node slurm-gpu-1
```

Try resuming the node:

```bash
scontrol update NodeName=slurm-gpu-1 State=RESUME
sinfo
```

### Munge Decode Failed

If logs show:

```text
Munge decode failed: Invalid credential
```

Check whether both nodes use the same key:

```bash
sudo sha256sum /etc/munge/munge.key
```

Restart Munge on both nodes:

```bash
sudo systemctl restart munge
```

Then restart Slurm services:

Controller:

```bash
sudo systemctl restart slurmctld
```

Worker:

```bash
sudo systemctl restart slurmd
```

## Cleanup

Destroy all Terraform-managed resources:

```bash
terraform destroy
```

Or:

```bash
terraform destroy -auto-approve
```

After cleanup, confirm in AWS Console that these resources are removed:

- EC2 instances
- EBS volumes
- Security groups
- VPC
- Subnet
- Internet Gateway
- Route tables

## Next Steps

Planned improvements:

- Add placement group support
- Add `worker_count`
- Support 2 GPU workers
- Add PyTorch DDP smoke test
- Improve distributed training validation

**Structure:**
- `docs/`: Setup, commands, and architecture explanations
- `jobs/`: Example batch scripts
- `scripts/`: Utility scripts to check Slurm status

