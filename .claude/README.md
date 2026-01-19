# Repo-Level Claude Code Configuration

This directory contains project-specific Claude Code configuration for the `_dotfiles` repository.

## Three-Layer Architecture

Claude Code uses a three-layer configuration system. This `.claude/` directory is the **Repo Layer** - configurations here apply only to this repository. See `CLAUDE.md` section "Claude Code Configuration" for full documentation of all layers.

## Directory Structure

```
.claude/
├── README.md       # This file
├── rules/          # Project-specific instruction rules (*.md files)
├── commands/       # Project-specific slash commands
└── hooks/          # Project-specific hook scripts
```

## Subdirectory Purposes

- **`rules/`** - Markdown files with project-specific rules and instructions. These are automatically loaded by Claude Code and supplement the global CLAUDE.md.

- **`commands/`** - Custom slash commands specific to this project. Create `.md` files here to add project-local commands.

- **`hooks/`** - JavaScript hook scripts for project-specific automation (PreToolUse, PostToolUse, etc.).

## Auto-Gitignored Files

The following files are auto-gitignored by Claude Code and should not be committed:

- `settings.json` - Project settings (may contain sensitive configuration)
- `settings.local.json` - Local overrides

## Layer Ownership

| Layer | Ownership | This repo's role |
|-------|-----------|------------------|
| User (`~/.claude/`) | Ansible playbook | Defines scaffold via `tools/claude-code/` |
| Portable (`~/.claude/<name>/`) | Package installers | N/A (installed separately) |
| Repo (`.claude/`) | This repository | This directory |
