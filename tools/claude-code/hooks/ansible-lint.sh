#!/bin/bash
# Claude Code post-tool hook: Run ansible-lint on recently edited YAML files
# Triggered after Edit/Write - checks staged .yml files

# Only run in _dotfiles repo
[[ "$PWD" != *"_dotfiles"* ]] && exit 0

# Check if ansible-lint is available
command -v ansible-lint >/dev/null 2>&1 || exit 0

# Get recently modified .yml files (staged or unstaged)
YML_FILES=$(git diff --name-only HEAD 2>/dev/null | grep '\.yml$' | head -5)
[ -z "$YML_FILES" ] && YML_FILES=$(git diff --cached --name-only 2>/dev/null | grep '\.yml$' | head -5)
[ -z "$YML_FILES" ] && exit 0

# Run ansible-lint on each file
FAILED=0
OUTPUT=""

for FILE in $YML_FILES; do
    [ -f "$FILE" ] || continue
    RESULT=$(ansible-lint "$FILE" 2>&1)
    if [ $? -ne 0 ]; then
        FAILED=1
        OUTPUT="$OUTPUT\n--- $FILE ---\n$RESULT"
    fi
done

# If all passed, exit silently
[ $FAILED -eq 0 ] && exit 0

# Lint failed - output errors for Claude to see and fix
echo -e "ansible-lint errors detected:$OUTPUT"
exit 1
