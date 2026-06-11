#!/usr/bin/env bash
set -euo pipefail

KEY="${1:-}"
if [ -z "$KEY" ]; then
  echo "Usage: $0 /path/to/key.pem"
  exit 1
fi

cd "$(dirname "$0")/../terraform"
IP="$(terraform output -raw controller_public_ip)"
ssh -i "$KEY" ubuntu@"$IP"
