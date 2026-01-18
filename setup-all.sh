#!/usr/bin/env bash
#
# Run setup.yml against all nodes in inventory, including localhost
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

CURRENT_HOST="$(hostname -s)"

echo "Running setup.yml on local host ($CURRENT_HOST)..."
ansible-playbook setup.yml --connection=local --limit "$CURRENT_HOST" "$@"

echo "Running setup.yml on remote hosts..."
ansible-playbook setup.yml --limit "all:!$CURRENT_HOST" "$@"
