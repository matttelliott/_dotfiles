#!/usr/bin/env bash
set -euo pipefail

# cron/launchd run with a minimal PATH — Homebrew (mac), /usr/local (linux),
# and ~/.local/bin (claude CLI) need to be findable
export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd ~/_dotfiles

OLD_SHA=$(git rev-parse HEAD)
git pull --ff-only || exit 1
NEW_SHA=$(git rev-parse HEAD)

if [[ "$OLD_SHA" != "$NEW_SHA" ]]; then
  "$SCRIPT_DIR/changelog.sh" update "$OLD_SHA" "$NEW_SHA" || true
fi

# Use the checked-in inventory.yml (default via ansible.cfg) — works regardless of whether
# this machine was self-setup via bootstrap.sh or provisioned from a control node.
ansible-playbook setup.yml --connection=local --limit "$(hostname -s)"
