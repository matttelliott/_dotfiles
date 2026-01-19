# Claude Code Configuration

## Current State

**Shipped:** v1.0 Config Cleanup (2026-01-19)

The three-layer Claude Code configuration architecture is now established:
- **User layer** (`~/.claude/`): Clean with only GSD + credentials
- **Portable layer** (`~/.claude/<name>/`): GSD installed via npx
- **Repo layer** (`.claude/`): Scaffolded with README and subdirectories

Documentation lives in `CLAUDE.md` under "## Claude Code Configuration".

## Current Milestone: v1.1 Multi-agent Safety

**Goal:** Make multi-agent work safe through git worktree isolation integrated with GSD workflows.

**Target features:**
- Git worktree strategy for multi-agent isolation (each agent gets its own branch/directory)
- GSD integration (execute-phase sets up worktree, completion merges/squashes)
- Squash-on-merge for clean commit history on master
- Claude awareness (stop retrying commits when nothing to commit)

## What This Is

Cleanup and restructuring of Claude Code configuration for the dotfiles repo. Establishing a clean three-layer config architecture (user / portable / repo-specific) as a foundation for future Claude integrations.

## Core Value

Clean, organized config structure that makes it obvious where things belong — user-level globals, portable workflows like GSD, and repo-specific customizations.

## Requirements

### Validated

- ✓ Remove legacy Claude configs (user + repo level) — v1.0
- ✓ Design config layer structure (user / portable / repo-specific) — v1.0
- ✓ Implement clean directory structure at each layer — v1.0
- ✓ Document what belongs where — v1.0

### Active

- [ ] Git worktree isolation for multi-agent work
- [ ] GSD integration with worktree workflow
- [ ] Squash-on-merge for clean history
- [ ] Claude awareness of autocommit (stop retrying empty commits)

### Out of Scope

- Feature explorer workflow (explore → propose → demo → configure → promote) — future milestone
- MCP server configuration — complexity; defer until needed
- Applied repo multi-agent strategy (dotfiles, k8s) — needs more thought, defer

## Context

**Tech stack:** Ansible, Bash, YAML
**Codebase:** Dotfiles repo with 90+ tools, mature and working

Previous Claude Code customization attempts were clunky:
- Autocommit hook works but Claude doesn't know about it
- Commit messages from hook are poor quality
- Multiple agents create mangled git history

Foundation now clean and ready for intentional development.

## Constraints

- **Preserve GSD**: All GSD functionality must continue working
- **Preserve auth**: Credentials file untouched
- **Three layers**: user (`~/.claude/`), portable (`~/.claude/<name>/`), repo (`.claude/`)

## Key Decisions

| Decision                        | Rationale                                              | Outcome   |
| ------------------------------- | ------------------------------------------------------ | --------- |
| Keep only GSD + creds           | Previous experiments weren't working well, clean slate | ✓ v1.0    |
| Three-layer config architecture | Clear separation: global, portable, project-specific   | ✓ v1.0    |
| Cleanup before building         | Foundation first, features later                       | ✓ v1.0    |
| User layer owns scaffold        | Ansible creates dirs, portables populate content       | ✓ v1.0    |
| Subdirectory .gitkeeps          | Cleaner structure than single root .gitkeep            | ✓ v1.0    |

---

_Last updated: 2026-01-19 after v1.1 milestone initialization_
