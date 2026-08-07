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

# Per-account settings, written by tools/self-update/install_self-update.yml.
# Deliberately kept OUTSIDE the repo: this script is tracked in git and is
# still executing while `git pull` above runs, so anything generated must not
# live in the working tree.
#
#   DOTFILES_LIMIT      inventory entry that provisioned this account
#   DOTFILES_INVENTORY  inventory file that entry lives in, relative to here
#   DOTFILES_SKIP_TAGS  "system" for standard (non-admin) accounts
DOTFILES_LIMIT=""
DOTFILES_INVENTORY=""
DOTFILES_SKIP_TAGS=""
# shellcheck source=/dev/null
[[ -f "$HOME/.config/dotfiles/self-update.env" ]] && source "$HOME/.config/dotfiles/self-update.env"

# On a multi-user host each account has its own inventory entry (macmini,
# macmini-alice, ...), so they cannot all match the machine's hostname. Fall
# back to the hostname for accounts provisioned before this config existed.
LIMIT="${DOTFILES_LIMIT:-$(hostname -s)}"

ARGS=()
# Re-use whichever inventory provisioned this account: localhost.yml for a
# machine set up by bootstrap.sh, inventory.yml when driven from a control
# node. Falls back to the ansible.cfg default (inventory.yml) for accounts
# provisioned before this config existed.
if [[ -n "$DOTFILES_INVENTORY" && -f "$DOTFILES_INVENTORY" ]]; then
	ARGS+=(-i "$DOTFILES_INVENTORY")
fi
if [[ -n "$DOTFILES_SKIP_TAGS" ]]; then
	ARGS+=(--skip-tags "$DOTFILES_SKIP_TAGS")
fi

ansible-playbook setup.yml --connection=local --limit "$LIMIT" ${ARGS[@]+"${ARGS[@]}"}
