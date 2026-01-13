#!/bin/bash
cd /Users/matt/_dotfiles

# Fetch and check for changes
git fetch origin master
LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse origin/master)

if [ "$LOCAL" != "$REMOTE" ]; then
  echo "=== Sync started at $(date) ===" >> /Users/matt/.dotfiles-sync.log

  # Check for local changes (uncommitted or ahead of remote)
  if ! git diff --quiet || ! git diff --cached --quiet || [ "$(git rev-list origin/master..HEAD)" ]; then
    BACKUP_BRANCH="macbookair-backup-$(date +%Y%m%d-%H%M%S)"
    echo "Backing up local changes to $BACKUP_BRANCH" >> /Users/matt/.dotfiles-sync.log
    git stash --include-untracked >> /Users/matt/.dotfiles-sync.log 2>&1
    git checkout -b "$BACKUP_BRANCH" >> /Users/matt/.dotfiles-sync.log 2>&1
    git stash pop >> /Users/matt/.dotfiles-sync.log 2>&1 || true
    git add -A >> /Users/matt/.dotfiles-sync.log 2>&1
    git commit -m "Backup from macbookair before sync" >> /Users/matt/.dotfiles-sync.log 2>&1 || true
    git push origin "$BACKUP_BRANCH" >> /Users/matt/.dotfiles-sync.log 2>&1
    git checkout master >> /Users/matt/.dotfiles-sync.log 2>&1
  fi

  git reset --hard origin/master >> /Users/matt/.dotfiles-sync.log 2>&1
  ansible-playbook setup.yml --connection=local --limit macbookair >> /Users/matt/.dotfiles-sync.log 2>&1
  echo "=== Sync completed at $(date) ===" >> /Users/matt/.dotfiles-sync.log
fi
