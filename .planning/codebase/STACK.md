# Technology Stack

**Analysis Date:** 2026-01-19

## Languages

**Primary:**
- YAML - Ansible playbooks and configurations (all `tools/*/install_*.yml`)
- Bash - Bootstrap script and shell configurations (`bootstrap.sh`, `tools/*/*.zsh`)

**Secondary:**
- TypeScript - Pulumi infrastructure code (`infrastructure/index.ts`)
- Lua - Neovim configuration (`tools/neovim/nvim/init.lua`)
- Jinja2 - Ansible templates (`tools/*/*.j2`)

## Runtime

**Environment:**
- Ansible 2.x+ (core automation framework)
- Python 3 (required by Ansible)
  - macOS: `/opt/homebrew/bin/python3`
  - Linux: `/usr/bin/python3`

**Package Manager:**
- None for root project (Ansible collections only)
- npm/pnpm for infrastructure (`infrastructure/package.json`)
- Lockfile: Not present in infrastructure/

## Frameworks

**Core:**
- Ansible - Configuration management and deployment automation
- community.sops (>=1.6.0) - Encrypted secrets support via `requirements.yml`

**Infrastructure:**
- Pulumi ^3.113.0 - Infrastructure as Code for cloud resources
- @pulumi/digitalocean 4.56.0 - DigitalOcean provider

**Build/Dev:**
- TypeScript ^5.0.0 - For infrastructure code compilation
- @types/node ^18 - Node.js type definitions

## Key Dependencies

**Ansible Collections:**
- `community.sops` - Decrypts SOPS-encrypted variables (Age encryption)

**Infrastructure (npm):**
- `@pulumi/pulumi` - Pulumi SDK
- `@pulumi/digitalocean` - DigitalOcean resource management

## Configuration

**Environment:**
- `~/.config/sops/age/keys.txt` - Age private key for SOPS decryption
- `~/.config/op/service-account-token` - 1Password service account token
- Configuration via Ansible group_vars:
  - `group_vars/all/defaults.yml` - Default values
  - `group_vars/all/personal-info.sops.yml` - Encrypted personal data

**Inventory:**
- `ansible.cfg` - Ansible configuration
- `inventory.yml` - Remote machine inventory
- `localhost.yml` - Generated local inventory (not committed)

**Build:**
- `infrastructure/tsconfig.json` - TypeScript compiler config (ES2020, CommonJS)

## Managed Languages/Runtimes

The playbooks install and configure these development environments:

**Node.js:**
- Installed via NVM (Node Version Manager)
- LTS version by default
- Global packages: typescript, @fsouza/prettierd, eslint_d
- Config: `tools/node/install_node.yml`

**Python:**
- Managed via UV (Astral's Python package manager)
- Dev tools: ruff, black, isort
- Config: `tools/python/install_python.yml`

**Rust:**
- Installed via rustup.rs
- Components: rustfmt, clippy, rust-analyzer
- Config: `tools/rust/install_rust.yml`

**Go:**
- Version 1.23.4
- Dev tools: gofumpt, goimports, gopls
- Config: `tools/go/install_go.yml`

**Lua:**
- Lua 5.4
- Dev tools: stylua (formatter)
- Config: `tools/lua/install_lua.yml`

## Platform Requirements

**Supported Operating Systems:**
- macOS (Darwin) - Package manager: Homebrew
- Debian/Ubuntu - Package manager: apt
- Arch Linux - Package managers: pacman, yay (AUR)

**Development Prerequisites:**
- SSH access for remote hosts
- sudo/become access for package installation
- Age key for secrets decryption (optional)
- 1Password service account for SSH key retrieval (optional)

**Production:**
- DigitalOcean Droplets (managed via Pulumi)
- Debian 12 (debian-12-x64) droplet image
- Region: nyc1
- Size: s-2vcpu-4gb

## Tool Count

The repository manages **101 tools** across these categories:

**Development:**
- Editors: neovim, nvim-ai
- Languages: node, python, rust, go, lua
- Version control: git, gh, lazygit

**DevOps/Cloud:**
- Container: docker, lazydocker
- Kubernetes: kubectl, k9s, helm, kubectx
- Cloud CLIs: doctl, awscli, gcloud, pulumi

**Security:**
- Secrets: 1password, 1password_cli, age, sops
- Network: wireguard, fail2ban, mullvad

**CLI Utilities:**
- Search: ripgrep, fd, fzf
- File viewing: bat, eza, tree
- System: htop, btop, procs, duf, dust

**GUI Applications:**
- Terminals: wezterm
- Browsers: chrome, firefox, brave, librewolf, zen, etc.
- AI: claude-code, claude-desktop, chatgpt-desktop

---

*Stack analysis: 2026-01-19*
