# _dotfiles

## What This Is

Personal dotfiles for provisioning new machines with a consistent development environment. Ansible-based, cross-platform (macOS, Debian/Ubuntu, Arch Linux), managing 100+ tools and their configurations. One bootstrap command gets the full setup. Now with clean lint baseline and automated validation.

## Core Value

When you sit down at a new machine, one command gets you your environment.

## Current State

**Shipped:** v0.1 Lint & Tooling (2026-01-21)

Codebase: 107 YAML playbooks, all passing ansible-lint for targeted rules. Claude Code hook validates YAML edits automatically.

## Current Milestone: v0.2 Portability & Bugs

**Goal:** Fix architecture hardcoding and known bugs so playbooks work on ARM64 and re-runs are truly idempotent.

**Epic:** Concerns Resolution (v0.2–v0.5) — addressing all items from `.planning/codebase/CONCERNS.md`

**Milestone roadmap:**

| Milestone | Theme | Key Deliverables |
|-----------|-------|------------------|
| **v0.2** | Portability & Bugs | ARM64 support, idempotency guards, bug fixes |
| **v0.3** | CI/CD & Testing | GitHub Actions pipeline, Molecule tests |
| **v0.4** | Security & Documentation | Curl-to-shell hardening, risk documentation |
| **v0.5** | Polish | Themes refactor, Homebrew optimization, version tracking |

**WONTFIX (with rationale):**
- SEC-03 (token plaintext) — already mitigated with 600 perms
- SEC-04 (SSH key handling) — already mitigated with no_log
- PERF-03 (neovim size) — kickstart pattern, has extensions
- FRAG-02 (nerd fonts) — already documented in CLAUDE.md
- SCALE-01/02 (inventory/groups) — 4 hosts, 7 groups sufficient
- DEP-02 (yay/AUR) — standard Arch practice
- MISS-03 (version lock) — rolling releases preferred

**DEFERRED:**
- PERF-02 (parallel installation) — complexity vs benefit
- TEST-03 (cross-platform CI) — platform matrix expensive

## Requirements

### Validated

<!-- Shipped and confirmed valuable. -->

- ✓ Bootstrap new machine via curl | bash — existing
- ✓ Cross-platform support (macOS, Debian, Arch) — existing
- ✓ 100+ tools installed and configured — existing
- ✓ Per-tool modularity (install one tool or all) — existing
- ✓ Host group feature flags (GUI tools, browsers, AI tools) — existing
- ✓ Secrets management (SOPS + Age + 1Password) — existing
- ✓ Coordinated theming across tmux/starship/neovim — existing
- ✓ Idempotent execution (safe to re-run) — existing
- ✓ Remote host provisioning via SSH — existing
- ✓ All playbooks pass ansible-lint (targeted rules) — v0.1
- ✓ Claude Code hook validates YAML on write — v0.1

### Active

<!-- Current scope. Building toward these. -->

**v0.2 Portability & Bugs:**
- [ ] ARM64 architecture support for APT repositories (docker, 1password, edge)
- [ ] Dynamic architecture detection for Go installation
- [ ] Idempotency guards for shell commands (go install, mason, npm, uv)
- [ ] SSH known_hosts marker file bug fix
- [ ] Debian non-free repos safe modification
- [ ] Homebrew update optimization

### Out of Scope

<!-- Explicit boundaries. Includes reasoning to prevent re-adding. -->

- Windows support — different paradigm, WSL sufficient
- GUI configuration tool — CLI/playbook interface works fine
- Automatic updates/scheduled runs — manual control preferred
- Full ansible-lint compliance — 267 non-targeted violations remain (command-instead-of-shell, risky-file-permissions, etc.) tracked as tech debt for v0.3+

## Context

Mature codebase with established patterns. Key architecture:
- `bootstrap.sh` — entry point for new machines
- `setup.yml` — main orchestration playbook
- `tools/<name>/install_<name>.yml` — per-tool playbooks with OS conditionals
- `tools/<name>/<name>.zsh` — shell integrations sourced by zshrc
- `group_vars/all/` — shared variables and encrypted secrets
- `themes/` — coordinated color/font/style changes
- `.claude/settings.json` — Claude Code hooks (ansible-lint on YAML edits)

Work typically involves: adding new tools, updating configs, fixing breakage after OS updates.

## Constraints

- **Cross-platform**: Must work on macOS, Debian, and Arch — that's the point
- **Idempotent**: Playbooks must be safe to re-run without side effects
- **No secrets in git**: All sensitive data encrypted via SOPS or fetched from 1Password

## Key Decisions

<!-- Decisions that constrain future work. Add throughout project lifecycle. -->

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Ansible for automation | Declarative, idempotent, multi-OS support, mature ecosystem | ✓ Good |
| Per-tool modularity | Can install single tool or everything, easy to add new tools | ✓ Good |
| SOPS + Age for secrets | No GPG complexity, works well with git | ✓ Good |
| Host groups for features | Flexible per-machine customization without duplication | ✓ Good |
| Repo-level Claude Code hooks | Shared hooks in .claude/settings.json, personal in settings.local.json | ✓ Good |
| Targeted lint fixes first | Fix FQCN/truthy/name violations, defer risky-* and command-* to later | ✓ Good |
| version: master for git | ansible-lint requires explicit branch, HEAD not recognized | ✓ Good |

---
*Last updated: 2026-01-21 after starting v0.2 milestone (Concerns Resolution epic)*
