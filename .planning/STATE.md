# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-01-21)

**Core value:** One command gets you your environment on any new machine
**Current focus:** v0.2 Portability & Bugs (Phase 7)

## Current Position

Phase: 6 (Idempotency Guards) — complete
Milestone: v0.2 Portability & Bugs
Epic: Concerns Resolution (v0.2–v0.5)
Status: Ready for Phase 7
Last activity: 2026-01-22 — Completed 06-01-PLAN.md

Progress: ███░░░░░░░ 50% (2/4 phases in v0.2)

## Completed Milestones

- **v0.1 Lint & Tooling** (2026-01-21) — 4 phases, 4 plans
  - See: .planning/milestones/v0.1-ROADMAP.md

## Performance Metrics

**v0.1 Velocity:**
- Total plans completed: 4
- Average duration: ~15 min/plan
- Total execution time: ~1 hour
- Timeline: 2 days (2026-01-20 → 2026-01-21)

**v0.2 Velocity:**
- Total plans completed: 3
- Average duration: ~5 min/plan
- Total execution time: ~17 min
- Timeline: 2 days (2026-01-21 → 2026-01-22)

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01 | 3/3 | ~1h | ~20m |
| 04 | 1/1 | ~2m | ~2m |
| 05 | 2/2 | ~16m | ~8m |
| 06 | 1/1 | ~1m | ~1m |

*Updated after each plan completion*

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions from v0.1:

- **gather_facts is not a module** (01-01): Playbook directive, not an Ansible module - must not use FQCN prefix
- **Comprehensive boolean field coverage** (01-01): Extended truthy fixes beyond common fields to include ignore_errors, remote_src, check_mode, append, enabled
- **Dependency import naming** (01-02): Use "Install {tool} (dependency)" pattern for import_playbook of prerequisites
- **version: master for git pins** (01-03): ansible-lint requires explicit branch name, not HEAD, to satisfy latest[git] rule
- **Shared hooks in settings.json** (04-01): Use .claude/settings.json (tracked) instead of settings.local.json (gitignored) for repo-level hooks
- **YAML folding for long lines** (05-01): Use >- syntax to break long repo URLs across lines for lint compliance
- **ARM64 skip pattern** (05-02): Use list-format when conditions with x86_64 check + aarch64 debug message for ARM64-incompatible tools

Recent decisions from v0.2:

- **Guard on first binary** (06-01): gofumpt for Go, ruff for Python - since all tools in each group are installed together, checking the first is sufficient
- **Same path for both OS** (06-01): uv symlinks tool binaries to ~/.local/bin regardless of OS, so the guard path is identical for macOS and Linux

### Pending Todos

2 pending todos — /gsd:check-todos to review

- Explore parallel GSD work patterns (planning)
- Build ChatGPT desktop app with Tauri (tools)

### Blockers/Concerns

None — ready for Phase 7

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 001 | Add ChatGPT Desktop Linux support | 2026-01-21 | 37b49fc | [001-add-chatgpt-app-tool](./quick/001-add-chatgpt-app-tool/) |
| 002 | Apply mosh to all hosts (desktop, macmini done; macbookair needs WG inventory) | 2026-01-21 | 98dc545 | [002-add-mosh-tool-and-apply-to-desktop](./quick/002-add-mosh-tool-and-apply-to-desktop/) |

## Session Continuity

Last session: 2026-01-22 (late night)
Stopped at: Completed todo cleanup session
Resume file: None
Next action: /gsd:plan-phase 7

### Session Summary (2026-01-22 night)

Completed 6 todos:
- tmux session sorting (`-O name` flag)
- Context7 + Sequential Thinking MCPs added to claude-code playbook
- Claude Code switched to native installer
- WezTerm clip2path script for image pasting on Linux
- Fixed themes system (88 broken `ansible.builtin.replace:` params)
- Per-machine theme defaults in inventory + themesetting DEFAULTS option

Also fixed:
- Nerd Font Mono variant for WezTerm compatibility
- Desktop default font changed to monaspace

---
*State updated: 2026-01-22*
