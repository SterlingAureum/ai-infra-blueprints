#!/usr/bin/env bash
set -euo pipefail

echo "== Slurm services =="
systemctl is-active munge || true
systemctl is-active slurmctld || true
systemctl is-active slurmd || true

echo
echo "== Cluster nodes =="
sinfo || true

echo
echo "== Node details =="
scontrol show nodes || true

echo
echo "== Queue =="
squeue || true
