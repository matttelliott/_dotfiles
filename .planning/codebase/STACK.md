# Technology Stack

**Analysis Date:** 2026-01-19

## Languages

**Primary:**
- YAML - Ansible playbooks for tool installation and configuration
- Bash - Bootstrap script (`bootstrap.sh`) and shell configurations

**Secondary:**
- TypeScript - Pulumi IaC in `/infrastructure/`
- Lua - Neovim configuration in `tools/neovim/nvim/`
- Zsh - Shell configuration snippets in `tools/*/\*.zsh`

## Runtime

**Environment:**
- Python 3 - Required by Ansible
  - macOS: `/opt/homebrew/bin/python3`
  - Debian/Arch: `/usr/bin/python3`

**Package Managers:**
- Homebrew - macOS package management
- apt - Debian/Ubuntu package management
- pacman - Arch Linux package management
- yay - AUR helper for Arch Linux

**No lockfiles** - Ansible playbooks install tools via system package managers at latest versions.

## Frameworks

**Core:**
- Ansible - Primary automation framework for deployment and configuration
  - Version: System-installed via package managers
  - Collections: `community.sops >=1.6.0` (see `requirements.yml`)

**Infrastructure:**
- Pulumi ^3.113.0 - Infrastructure as Code for DigitalOcean
  - Runtime: Node.js (nodejs)
  - SDK: `@pulumi/digitalocean 4.56.0`

**Shell:**
- Zsh - Default shell with plugins:
  - zsh-autosuggestions
  - zsh-syntax-highlighting
- Starship - Cross-shell prompt

**Editor:**
- Neovim - Configured via `tools/neovim/nvim/init.lua`
- Mason - LSP/tool installer for Neovim

## Key Dependencies

**Ansible Collections:**
- `community.sops` - Decryption of SOPS-encrypted variables

**Infrastructure (Pulumi):**
- `@pulumi/pulumi ^3.113.0` - Core Pulumi SDK
- `@pulumi/digitalocean 4.56.0` - DigitalOcean provider
- `typescript ^5.0.0` - TypeScript compiler
- `@types/node ^18` - Node.js type definitions

**Node.js Global Packages (installed via Ansible):**
- `@anthropic-ai/claude-code@latest` - Claude Code AI assistant
- `typescript` - TypeScript compiler
- `@fsouza/prettierd` - Prettier daemon
- `eslint_d` - ESLint daemon

**Python Tools (via uv):**
- `ruff` - Python linter
- `black` - Python formatter
- `isort` - Import sorter

## Language Runtimes Installed

**Node.js:**
- Manager: nvm (v0.40.1 on Linux, Homebrew on macOS)
- Version: LTS (default)
- Config: `tools/node/install_node.yml`

**Python:**
- Manager: uv (Astral)
- Version: System default
- Config: `tools/python/install_python.yml`

**Rust:**
- Manager: rustup
- Components: rustfmt, clippy, rust-analyzer
- Config: `tools/rust/install_rust.yml`

**Go:**
- Version: 1.23.4 (hardcoded in playbook)
- Tools: gofumpt, goimports, gopls
- Config: `tools/go/install_go.yml`

**Lua:**
- Version: 5.4 (Debian), latest (others)
- Tools: stylua
- Config: `tools/lua/install_lua.yml`

## Configuration

**Environment:**
- Secrets: SOPS-encrypted YAML in `group_vars/all/personal-info.sops.yml`
- Encryption: Age encryption (key at `~/.config/sops/age/keys.txt`)
- 1Password: Service account token at `~/.config/op/service-account-token`

**Ansible Config (`ansible.cfg`):**
```ini
inventory = inventory.yml
collections_path = ~/.ansible/collections
vars_plugins_enabled = host_group_vars,community.sops.sops
age_keyfile = ~/.config/sops/age/keys.txt
```

**Build (Pulumi):**
- `infrastructure/Pulumi.yaml` - Project definition
- `infrastructure/Pulumi.dev.yaml` - Dev stack config
- `infrastructure/tsconfig.json` - TypeScript config (ES2020, strict mode)

## Platform Support

**Operating Systems:**
- macOS (Darwin) - Apple Silicon (ARM64)
- Debian/Ubuntu - x86_64
- Arch Linux - x86_64

**OS Detection:** `ansible_facts['os_family']` with values:
- `Darwin` - macOS
- `Debian` - Debian/Ubuntu
- `Archlinux` - Arch Linux

## Tool Count

**Total Tools:** 101 directories in `tools/`
**Install Playbooks:** ~3,856 lines across all `install_*.yml` files

## Key Configuration Patterns

**Jinja2 Templates:**
- `tools/*/\*.j2` - Templated configs (tmux, git, ssh)
- Variables from `group_vars/all/personal-info.sops.yml` (encrypted)

**Shell Configuration:**
- Tool-specific: `tools/*/*.zsh` sourced in `~/.zshrc`
- Base zshrc: `tools/zsh/zshrc`

**Neovim:**
- Single-file config: `tools/neovim/nvim/init.lua` (~45k characters)
- Formatting: `tools/neovim/nvim/.stylua.toml`

---

*Stack analysis: 2026-01-19*
