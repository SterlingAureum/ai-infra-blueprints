# Local Single-node Slurm Setup

## VM Requirements
- Ubuntu 22.04 LTS
- CPU: 2-4 cores
- Memory: 4-8 GB
- Disk: 30-50 GB

## Hostname & Hosts
```bash
sudo hostnamectl set-hostname slurm-lab
sudo nano /etc/hosts  # ensure 127.0.1.1 slurm-lab exists
```

## Install Packages
```bash
sudo apt update
sudo apt install -y munge slurm-wlm slurm-wlm-basic-plugins
```

## Munge Setup
```bash
sudo create-munge-key
sudo chown -R munge:munge /etc/munge /var/lib/munge /var/log/munge
sudo chmod 400 /etc/munge/munge.key
sudo systemctl enable --now munge
munge -n | unmunge  # test
```

## Slurm Directories
```bash
sudo mkdir -p /var/spool/slurmctld /var/spool/slurmd /var/log/slurm
sudo chown -R slurm:slurm /var/spool/slurmctld /var/spool/slurmd /var/log/slurm
```

## Minimal slurm.conf
- Edit `/etc/slurm/slurm.conf` with NodeName, CPUs, RealMemory
- Partition: `debug`
- AuthType: `auth/munge`
- SchedulerType: `sched/backfill`
- See baseline example in repo

## Start Services
```bash
sudo systemctl enable --now slurmctld
sudo systemctl enable --now slurmd
```

## Validate
```bash
sinfo
srun hostname
sbatch jobs/hello-slurm.sbatch
```
