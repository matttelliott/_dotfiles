---
created: 2026-01-19T02:25
title: Support containerized environments for Claude
area: tooling
files: []
---

## Problem

Claude Code may need to run in containerized environments (Docker, devcontainers, etc.). The current dotfiles setup may not account for container-specific considerations like:
- Volume mounts for ~/.claude/
- Network access for credentials
- Path differences between host and container
- Persistence of configuration across container rebuilds

## Solution

TBD - needs research into:
1. How Claude Code works in containers
2. Best practices for dotfiles in containerized dev environments
3. Whether Ansible deployment needs container-aware conditionals
