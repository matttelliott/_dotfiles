# _dotfiles

## What This Is

Personal dotfiles for provisioning new machines with a consistent development environment. Ansible-based, cross-platform (macOS, Debian/Ubuntu, Arch Linux), managing 100+ tools and their configurations. One bootstrap command gets the full setup.

## Core Value

When you sit down at a new machine, one command gets you your environment.

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

### Active

<!-- Current scope. Building toward these. -->

(None currently — add items as new work arises)

### Out of Scope

<!-- Explicit boundaries. Includes reasoning to prevent re-adding. -->

- Windows support — different paradigm, WSL sufficient
- GUI configuration tool — CLI/playbook interface works fine
- Automatic updates/scheduled runs — manual control preferred

## Context

Mature codebase with established patterns. Key architecture:
- `bootstrap.sh` — entry point for new machines
- `setup.yml` — main orchestration playbook
- `tools/<name>/install_<name>.yml` — per-tool playbooks with OS conditionals
- `tools/<name>/<name>.zsh` — shell integrations sourced by zshrc
- `group_vars/all/` — shared variables and encrypted secrets
- `themes/` — coordinated color/font/style changes

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

---
*Last updated: 2026-01-19 after initialization*
