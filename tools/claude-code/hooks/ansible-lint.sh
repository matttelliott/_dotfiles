#!/bin/bash
# Claude Code post-tool hook: Run ansible-lint on edited YAML files
# Triggered after Edit/Write on .yml files in _dotfiles repo

# Get the edited file path from environment
FILE_PATH="${CLAUDE_FILE_PATH:-}"

# Exit silently if no file path
[ -z "$FILE_PATH" ] && exit 0

# Only check .yml files
[[ "$FILE_PATH" != *.yml ]] && exit 0

# Only run in _dotfiles repo
[[ "$PWD" != *"_dotfiles"* ]] && exit 0

# Check if ansible-lint is available
command -v ansible-lint >/dev/null 2>&1 || exit 0

# Run ansible-lint on the specific file
OUTPUT=$(ansible-lint "$FILE_PATH" 2>&1)
EXIT_CODE=$?

# If lint passed, exit silently
[ $EXIT_CODE -eq 0 ] && exit 0

# Lint failed - output errors for Claude to see and fix
echo "ansible-lint failed for $FILE_PATH:"
echo "$OUTPUT"
exit 1
