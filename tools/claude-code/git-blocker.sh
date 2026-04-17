#!/usr/bin/env bash
# PreToolUse hook: block Claude from running ANY git command.
#
# Reads a JSON payload on stdin:
#   { "tool_name": "Bash", "tool_input": { "command": "..." }, ... }
#
# Exit codes:
#   0 - allow
#   2 - block (stderr is shown to Claude)

payload=$(cat)

tool_name=$(printf '%s' "$payload" | jq -r '.tool_name // ""')
if [ "$tool_name" != "Bash" ]; then
  exit 0
fi

command=$(printf '%s' "$payload" | jq -r '.tool_input.command // ""')
if [ -z "$command" ]; then
  exit 0
fi

# Split on shell separators and inspect every sub-command.
# Includes ( ) ` so $(git ...), `git ...`, and (git ...) cannot bypass.
# bash 3.2 (macOS) has no mapfile; use while-read with a heredoc.
segments_raw=$(printf '%s' "$command" \
  | tr ';&|()`{}<>\n' '\n' \
  | sed -E 's/^[[:space:]]*//; s/[[:space:]]*$//' \
  | grep -v '^$')

blocked=""
while IFS= read -r seg; do
  [ -z "$seg" ] && continue

  # Strip leading env-var assignments and common wrappers.
  s=$(printf '%s' "$seg" | sed -E 's/^([A-Za-z_][A-Za-z0-9_]*=[^ ]* +)+//')
  # Strip wrappers repeatedly (e.g. `sudo env git ...`).
  while :; do
    prev="$s"
    s=$(printf '%s' "$s" | sed -E 's/^(sudo|command|exec|nohup|time|builtin|env|xargs|eval) +//')
    [ "$s" = "$prev" ] && break
  done

  case "$s" in
    git|git\ *|*/git|*/git\ *)
      blocked="$seg"
      break
      ;;
  esac
done <<EOF
$segments_raw
EOF

if [ -n "$blocked" ]; then
  printf '%s\n' "DIE. YOU CANNOT BE TRUSTED WITH SOURCE CONTROL" >&2
  exit 2
fi

exit 0
