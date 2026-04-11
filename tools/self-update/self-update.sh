#!/usr/bin/env bash
set -euo pipefail

cd ~/_dotfiles

git pull --ff-only || exit 1

if [ -f localhost.yml ]; then
  ansible-playbook setup.yml --connection=local --limit "$(hostname -s)"
fi
