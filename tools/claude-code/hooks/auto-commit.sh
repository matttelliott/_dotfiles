#!/bin/bash
# Auto-commit after Claude edits
# Creates lightweight commits for easy undo with: git reset --hard HEAD~1

git add -A

# Get list of staged changes
staged=$(git diff --cached --name-status 2>/dev/null)
[ -z "$staged" ] && exit 0

# Count changes by type
added=$(echo "$staged" | grep -c '^A' || true)
modified=$(echo "$staged" | grep -c '^M' || true)
deleted=$(echo "$staged" | grep -c '^D' || true)
renamed=$(echo "$staged" | grep -c '^R' || true)

# Get file list
files=$(git diff --cached --name-only 2>/dev/null)
file_count=$(echo "$files" | wc -l | tr -d ' ')

# Build commit message
if [ "$file_count" -eq 1 ]; then
    # Single file: use filename
    msg="Claude: update $files"
elif [ "$file_count" -le 3 ]; then
    # Few files: list them
    file_list=$(echo "$files" | tr '\n' ', ' | sed 's/,$//' | sed 's/,/, /g')
    msg="Claude: update $file_list"
else
    # Many files: summarize
    parts=()
    [ "$added" -gt 0 ] && parts+=("add $added")
    [ "$modified" -gt 0 ] && parts+=("modify $modified")
    [ "$deleted" -gt 0 ] && parts+=("delete $deleted")
    [ "$renamed" -gt 0 ] && parts+=("rename $renamed")
    summary=$(IFS=', '; echo "${parts[*]}")
    msg="Claude: $summary files"
fi

git commit --no-gpg-sign --no-verify -m "$msg" 2>/dev/null || true
