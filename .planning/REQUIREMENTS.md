# Requirements: _dotfiles

**Defined:** 2026-01-19
**Core Value:** One command gets you your environment on any new machine

## Validated

<!-- Shipped and confirmed valuable. These are what the dotfiles already do. -->

### Bootstrap
- ✓ **BOOT-01**: New machine provisioned via `curl | bash`
- ✓ **BOOT-02**: OS auto-detected (macOS, Debian, Arch)
- ✓ **BOOT-03**: Interactive host group selection during bootstrap

### Tools
- ✓ **TOOL-01**: 100+ tools installed and configured
- ✓ **TOOL-02**: Per-tool modularity (can install one or all)
- ✓ **TOOL-03**: OS-specific installation paths (brew/apt/pacman)
- ✓ **TOOL-04**: Shell integrations sourced automatically

### Configuration
- ✓ **CONF-01**: Host group feature flags (GUI, browsers, AI tools)
- ✓ **CONF-02**: Coordinated theming across tmux/starship/neovim
- ✓ **CONF-03**: Idempotent execution (safe to re-run)

### Security
- ✓ **SECR-01**: Secrets encrypted via SOPS + Age
- ✓ **SECR-02**: SSH keys from 1Password
- ✓ **SECR-03**: No secrets committed to git

### Remote
- ✓ **REMT-01**: Provision remote hosts via SSH
- ✓ **REMT-02**: DigitalOcean droplet management via Pulumi

## Active

<!-- Current work. Add items when starting new improvements. -->

(None currently)

## Out of Scope

| Feature | Reason |
|---------|--------|
| Windows support | Different paradigm, WSL sufficient |
| GUI config tool | CLI/playbook interface works fine |
| Auto-updates | Manual control preferred |

---
*Requirements defined: 2026-01-19*
*Last updated: 2026-01-19 after initialization*
