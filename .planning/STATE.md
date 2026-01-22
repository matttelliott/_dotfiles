# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-01-21)

**Core value:** One command gets you your environment on any new machine
**Current focus:** v0.2 Portability & Bugs (Phase 8: LTS Version Policy)

## Current Position

Phase: 8 (LTS Version Policy) — complete
Milestone: v0.2 Portability & Bugs — complete
Epic: Concerns Resolution (v0.2–v0.5)
Status: v0.2 milestone complete
Last activity: 2026-01-22 — Completed 08-01-PLAN.md

Progress: ██████████ 100% (4/4 phases in v0.2)

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
- Total plans completed: 5
- Average duration: ~4 min/plan
- Total execution time: ~19 min
- Timeline: 2 days (2026-01-21 → 2026-01-22)

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01 | 3/3 | ~1h | ~20m |
| 04 | 1/1 | ~2m | ~2m |
| 05 | 2/2 | ~16m | ~8m |
| 06 | 1/1 | ~1m | ~1m |
| 07 | 2/2 | ~3m | ~1.5m |
| 08 | 1/1 | ~31s | ~31s |

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
- **ssh-keygen -F pattern** (07-01): Use command module (not shell) for ssh-keygen -F, with changed_when/failed_when for lint compliance
- **deb822_repository over apt_repository** (07-02): Modern module creates proper .sources files in deb822 format, safer than modifying sources.list directly
- **Phase 8 scope change** (08-discuss): Replaced PERF-01 (Homebrew skipping) with LTS-01 (LTS version policy) — user prefers always-update and LTS versions
- **LTS version hierarchy** (08-01): Documented LTS > stable > latest version selection policy with implementation table

### Pending Todos

0 pending todos — /gsd:check-todos to review


### Blockers/Concerns

None — v0.2 milestone complete, ready for v0.3 planning

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 001 | Add ChatGPT Desktop Linux support | 2026-01-21 | 37b49fc | [001-add-chatgpt-app-tool](./quick/001-add-chatgpt-app-tool/) |
| 002 | Apply mosh to all hosts (desktop, macmini done; macbookair needs WG inventory) | 2026-01-21 | 98dc545 | [002-add-mosh-tool-and-apply-to-desktop](./quick/002-add-mosh-tool-and-apply-to-desktop/) |

## Session Continuity

Last session: 2026-01-22
Stopped at: Completed 08-01-PLAN.md (Phase 8 complete, v0.2 milestone complete)
Resume file: None
Next action: /gsd:milestone for v0.3 planning

---
*State updated: 2026-01-22 (08-01 complete, v0.2 complete)*
