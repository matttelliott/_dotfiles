# Claude Code Configuration

## What This Is

Cleanup and restructuring of Claude Code configuration for the dotfiles repo. Establishing a clean three-layer config architecture (user / portable / repo-specific) as a foundation for future Claude integrations.

## Core Value

Clean, organized config structure that makes it obvious where things belong — user-level globals, portable workflows like GSD, and repo-specific customizations.

## Requirements

### Validated

- GSD installed and working at user level (`~/.claude/get-shit-done/`)
- Auth credentials functional (`~/.claude/.credentials.json`)
- Dotfiles repo has working Ansible automation for 90+ tools

### Active

- [ ] Remove old/broken claude configs (everything except GSD + creds)
- [ ] Design config layer structure (user / portable / repo-specific)
- [ ] Implement clean directory structure at each layer
- [ ] Document what belongs where

### Out of Scope

- Autocommit fixes (Claude awareness, better messages, multi-agent git) — future milestone
- Feature explorer workflow (explore → propose → demo → configure → promote) — future milestone
- New hooks or commands — get structure right first

## Context

Brownfield project. The dotfiles repo is mature and working. Previous Claude Code customization attempts were clunky:
- Autocommit hook works but Claude doesn't know about it, tries to commit when nothing to commit
- Commit messages from hook are poor quality
- Multiple agents create mangled git history
- Various experiments (output-styles, plugins, old commands) didn't stick

Starting fresh with just GSD + credentials, then building intentionally.

## Constraints

- **Preserve GSD**: All GSD functionality must continue working after cleanup
- **Preserve auth**: Credentials file untouched
- **Three layers**: user (`~/.claude/`), portable (`~/.claude/<name>/`), repo (`.claude/`)

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Keep only GSD + creds | Previous experiments weren't working well, clean slate | — Pending |
| Three-layer config architecture | Clear separation: global, portable, project-specific | — Pending |
| Cleanup before building | Foundation first, features later | — Pending |

---
*Last updated: 2026-01-18 after initialization*
