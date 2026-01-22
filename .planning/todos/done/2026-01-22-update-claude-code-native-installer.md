---
created: 2026-01-22T01:42
title: Update Claude Code to native installer
area: tools
files:
  - tools/claude-code/install_claude_code.yml
---

## Problem

Claude Code has migrated from npm-based installation to a native installer. The current dotfiles ansible playbook uses the npm approach:

```bash
npm install -g @anthropic-ai/claude-code
```

This is now deprecated and should be updated to use the native installer approach.

## Solution

1. Check current install method in `tools/claude-code/install_claude_code.yml`
2. Update to use native installer: `claude install` or follow docs at https://docs.anthropic.com/en/docs/claude-code/getting-started
3. Handle any platform-specific differences (macOS vs Linux)
4. Test on a fresh install to verify the migration works
