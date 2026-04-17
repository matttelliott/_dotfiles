#!/usr/bin/env bash
set -euo pipefail

# cron/launchd run with a minimal PATH — Homebrew (mac) and /usr/local (linux) need to be findable
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

cd ~/_dotfiles

git pull --ff-only || exit 1

# Use the checked-in inventory.yml (default via ansible.cfg) — works regardless of whether
# this machine was self-setup via bootstrap.sh or provisioned from a control node.
ansible-playbook setup.yml --connection=local --limit "$(hostname -s)"
