# Project Milestones: _dotfiles

## v0.2 Portability & Bugs (Shipped: 2026-01-22)

**Delivered:** ARM64 architecture support, idempotency guards for shell commands, bug fixes for SSH known_hosts and Debian repos, LTS version policy documentation.

**Phases completed:** 5-8 (6 plans total)

**Key accomplishments:**

- Dynamic architecture detection for Docker/Go playbooks (ARM64/x86_64)
- Graceful skip with debug messages for x86_64-only tools (1Password, Edge)
- `creates:` guards for Go, Python, Mason, npm shell tasks
- SSH known_hosts idempotency via ssh-keygen -F pattern
- Debian non-free repos via deb822_repository module
- LTS > stable > latest version policy documented in CLAUDE.md

**Stats:**

- 4 phases, 6 plans
- 2 days from start to ship (2026-01-21 → 2026-01-22)
- 11 requirements satisfied

**What's next:** v0.3 Security & Documentation

---

## v0.1 Lint & Tooling (Shipped: 2026-01-21)

**Delivered:** Clean ansible-lint baseline and Claude Code quality hook for ongoing lint validation.

**Phases completed:** 1-4 (4 plans total)

**Key accomplishments:**

- Eliminated 677 ansible-lint violations across 104 YAML files (FQCN, truthy, name[play], line-length, latest[git])
- Validated all playbooks still work via setup-all.sh on desktop and macmini
- Created ansible-lint hook for automatic validation on YAML edits
- Wired PostToolUse hook to Claude Code settings for real-time lint feedback

**Stats:**

- 104 files modified
- 1,181 insertions, 971 deletions (YAML style improvements)
- 4 phases, 4 plans
- 2 days from start to ship (2026-01-20 → 2026-01-21)

**Git range:** `4ecfe38` → `93fb2a9`

**What's next:** v0.2 Portability & Bugs

---
