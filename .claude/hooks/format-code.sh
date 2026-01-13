#!/bin/bash
# PostToolUse hook for formatting code after Edit/Write operations
# Receives JSON via stdin with tool_input.file_path

# Read JSON from stdin and extract file_path
file_path=$(jq -r '.tool_input.file_path // empty' 2>/dev/null)
[ -z "$file_path" ] && exit 0
[ ! -f "$file_path" ] && exit 0

case "$file_path" in
  *.lua)
    stylua "$file_path" 2>/dev/null
    ;;
  *.yml|*.yaml)
    yamlfmt "$file_path" 2>/dev/null
    ;;
esac

exit 0
