#!/usr/bin/env bash
set -euo pipefail

echo "== Slurm services =="
systemctl is-active munge || true
systemctl is-active slurmctld || true
systemctl is-active slurmd || true

echo
echo "== Slurm partitions and nodes =="
sinfo || true

echo
echo "== GPU-related node details =="
scontrol show nodes | grep -E "NodeName=|Gres=|CfgTRES=|AllocTRES=|State=" || true

echo
echo "== Local GPU devices =="
if command -v nvidia-smi >/dev/null 2>&1; then
  nvidia-smi || true
else
  echo "nvidia-smi not found"
fi

echo
echo "== Queue =="
squeue || true
