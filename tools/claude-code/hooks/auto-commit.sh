#!/bin/bash
# Auto-commit after Claude edits
# Creates lightweight commits for easy undo with: git reset --hard HEAD~1
# Squashes every 5 auto/wip commits into one with Claude-generated summary

SQUASH_THRESHOLD=5

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
    msg="Claude auto commit - $files"
elif [ "$file_count" -le 3 ]; then
    file_list=$(echo "$files" | tr '\n' ', ' | sed 's/,$//' | sed 's/,/, /g')
    msg="Claude auto commit - $file_list"
else
    parts=()
    [ "$added" -gt 0 ] && parts+=("add $added")
    [ "$modified" -gt 0 ] && parts+=("modify $modified")
    [ "$deleted" -gt 0 ] && parts+=("delete $deleted")
    [ "$renamed" -gt 0 ] && parts+=("rename $renamed")
    summary=$(IFS=', '; echo "${parts[*]}")
    msg="Claude auto commit - $summary files"
fi

git commit --no-gpg-sign --no-verify -m "$msg" 2>/dev/null || true

# --- Squash check ---

# Count consecutive auto/wip commits from HEAD
count=0
commits_to_squash=""
for sha in $(git log --format='%H' -n 50 2>/dev/null); do
    commit_msg=$(git log -1 --format='%s' "$sha" 2>/dev/null)
    if [[ "$commit_msg" =~ "Claude auto commit"* ]] || [[ "$commit_msg" =~ ^[Ww][Ii][Pp] ]]; then
        ((count++))
        commits_to_squash="$commits_to_squash $sha"
    else
        break
    fi
done

# Only squash if threshold reached
[ "$count" -lt "$SQUASH_THRESHOLD" ] && exit 0

# Get the commit before the oldest auto-commit
oldest_auto_commit=$(echo "$commits_to_squash" | awk '{print $NF}')
base_commit=$(git rev-parse "${oldest_auto_commit}^" 2>/dev/null)
[ -z "$base_commit" ] && exit 0

# Safety: don't squash if any commits have been pushed
remote_branch=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)
if [ -n "$remote_branch" ]; then
    remote_head=$(git rev-parse "$remote_branch" 2>/dev/null)
    if [ -n "$remote_head" ]; then
        git merge-base --is-ancestor "$remote_head" "$base_commit" 2>/dev/null || exit 0
    fi
fi

# Get diff for Claude to summarize
diff_content=$(git diff "$base_commit" HEAD 2>/dev/null)
[ -z "$diff_content" ] && exit 0

# Use Claude Code CLI to generate summary
squash_summary=$(echo "$diff_content" | claude -p "Summarize these changes in a single line (max 60 chars). Be specific about what was changed. Output only the summary, nothing else." 2>/dev/null)

# Fallback if claude fails
if [ -z "$squash_summary" ] || [ ${#squash_summary} -gt 80 ]; then
    squash_file_count=$(git diff --name-only "$base_commit" HEAD 2>/dev/null | wc -l | tr -d ' ')
    squash_summary="$squash_file_count files changed"
fi

squash_summary="Claude squashed auto-commits - $squash_summary"

# Perform soft reset and recommit
git reset --soft "$base_commit" 2>/dev/null || exit 0
git commit --no-gpg-sign --no-verify -m "$squash_summary" 2>/dev/null || true
git push
