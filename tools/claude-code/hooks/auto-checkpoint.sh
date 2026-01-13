#!/bin/bash
# Auto-checkpoint after Claude edits
# Creates lightweight commits for easy undo with: git reset --hard HEAD~1

git add -A && git commit --no-gpg-sign --no-verify -m 'Claude auto commit' 2>/dev/null || true
