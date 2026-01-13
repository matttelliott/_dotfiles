#!/bin/bash
cd /Users/matt/_dotfiles

# Fetch and check for changes
git fetch origin master
LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse origin/master)

if [ "$LOCAL" != "$REMOTE" ]; then
  echo "=== Sync started at $(date) ===" >> /Users/matt/.dotfiles-sync.log
  git pull origin master >> /Users/matt/.dotfiles-sync.log 2>&1
  ansible-playbook setup.yml --connection=local --limit macbookair >> /Users/matt/.dotfiles-sync.log 2>&1
  echo "=== Sync completed at $(date) ===" >> /Users/matt/.dotfiles-sync.log
fi
