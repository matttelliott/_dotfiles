#!/bin/bash
# Stop hook: Invoke prd-manager to update PRDs at end of turn

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')

# Marker prevents re-triggering after prd-manager runs
MARKER="/tmp/prd-hook-$SESSION_ID"
[ -f "$MARKER" ] && exit 0

# Find PRD directory
PRD_DIR=""
for dir in "docs/prd" "docs/prds" "prd" ".prd"; do
    [ -d "$dir" ] && PRD_DIR="$dir" && break
done
[ -z "$PRD_DIR" ] && exit 0

# Check for PRD files
[ -z "$(find "$PRD_DIR" -maxdepth 2 -name "*.md" 2>/dev/null)" ] && exit 0

# Set marker before invoking
touch "$MARKER"

cat << EOF
{
  "continue": true,
  "reason": "Use the Task tool with subagent_type 'prd-manager' to review and update PRDs in '$PRD_DIR' based on work completed this session."
}
EOF
