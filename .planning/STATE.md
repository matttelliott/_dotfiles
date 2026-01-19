# Project State

**Project:** _dotfiles
**Last Session:** 2026-01-19

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-01-19)

**Core value:** One command gets you your environment on any new machine
**Current focus:** Maintenance mode — no active phase

## Status

This is a maintenance project. Work happens ad-hoc:
- Adding new tools
- Updating configurations
- Fixing breakage after OS updates
- Tweaking to preference

## Codebase Map

See: `.planning/codebase/` (mapped 2026-01-19)

Key docs:
- `ARCHITECTURE.md` — System design and patterns
- `STACK.md` — Technologies and dependencies
- `STRUCTURE.md` — Directory layout
- `CONVENTIONS.md` — Code style and patterns
- `CONCERNS.md` — Technical debt and issues

## How to Work

When starting new work:

1. **Add a tool:** Create `tools/<name>/install_<name>.yml`, add to `setup.yml`
2. **Fix something:** Find the relevant playbook, make idempotent changes
3. **Add a feature:** Update PROJECT.md Active requirements, then implement

For significant work, use `/gsd:plan-phase` to create a focused plan.

## Recent Activity

- 2026-01-19: Project initialized, codebase mapped

---
*State updated: 2026-01-19*
