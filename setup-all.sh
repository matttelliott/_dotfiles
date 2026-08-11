#!/usr/bin/env bash
#
# Run setup.yml against all nodes in inventory, including localhost
#
# Hosts in the `standard_users` group are accounts on a machine some other
# entry already administers. They run with --skip-tags system so they never
# attempt a package install, service change, or sudoers edit they have no
# rights for. Everything else gets the full run.
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

CURRENT_HOST="$(hostname -s)"

# `ansible <group> --list-hosts` exits non-zero when the group is empty or
# undefined, which is the normal case on a single-user setup.
list_group() {
	ansible "$1" --list-hosts 2>/dev/null | tail -n +2 | tr -d ' ' || true
}

STANDARD_HOSTS="$(list_group standard_users)"

if [[ -n "$STANDARD_HOSTS" ]]; then
	ADMIN_PATTERN="all:!standard_users:!$CURRENT_HOST"
else
	ADMIN_PATTERN="all:!$CURRENT_HOST"
fi

echo "Running setup.yml on local host ($CURRENT_HOST)..."
ansible-playbook setup.yml --connection=local --limit "$CURRENT_HOST" "$@"

echo "Running setup.yml on remote hosts..."
ansible-playbook setup.yml --limit "$ADMIN_PATTERN" "$@"

if [[ -n "$STANDARD_HOSTS" ]]; then
	echo "Running setup.yml for standard user accounts (user-level config only)..."
	ansible-playbook setup.yml --limit "standard_users:!$CURRENT_HOST" --skip-tags system "$@"
fi
