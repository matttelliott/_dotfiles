#!/bin/bash
# PostToolUse hook for linting Ansible playbooks after Edit/Write operations
# Receives JSON via stdin with tool_input.file_path

# Read JSON from stdin and extract file_path
file_path=$(jq -r '.tool_input.file_path // empty' 2>/dev/null)
[ -z "$file_path" ] && exit 0
[ ! -f "$file_path" ] && exit 0

case "$file_path" in
  *.yml|*.yaml)
    ansible-lint "$file_path" 2>&1
    exit $?
    ;;
esac

exit 0
