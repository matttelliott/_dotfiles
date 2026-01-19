# Architecture

**Analysis Date:** 2026-01-19

## Pattern Overview

**Overall:** Configuration-as-Code with Ansible Orchestration

**Key Characteristics:**
- Declarative infrastructure management using Ansible playbooks
- Per-tool modular design with OS-agnostic abstraction layer
- Import-based composition in main playbook for execution ordering
- SOPS/Age encryption for secrets with 1Password integration
- Multi-platform targeting (macOS, Debian, Arch Linux)

## Layers

**Bootstrap Layer:**
- Purpose: Initial machine setup before Ansible is available
- Location: `bootstrap.sh`
- Contains: OS detection, dependency installation, inventory generation, 1Password/Age key setup
- Depends on: curl, bash (pre-existing on target systems)
- Used by: New machine provisioning

**Orchestration Layer:**
- Purpose: Coordinates tool installation order and manages execution
- Location: `setup.yml`, `setup-all.sh`
- Contains: Import statements, package manager cache updates, dotfiles clone/update
- Depends on: Ansible, inventory files
- Used by: All deployment runs (local and remote)

**Tool Layer:**
- Purpose: Individual tool installation and configuration
- Location: `tools/<tool>/install_<tool>.yml`
- Contains: OS-specific installation tasks, configuration deployment
- Depends on: Ansible facts for OS detection, group_vars for secrets
- Used by: Orchestration layer via import_playbook

**Configuration Layer:**
- Purpose: Tool-specific dotfiles and shell integrations
- Location: `tools/<tool>/<tool>.zsh`, `tools/<tool>/*.toml`, `tools/<tool>/nvim/`
- Contains: Shell aliases, environment variables, application configs
- Depends on: Installed tools
- Used by: User shell sessions, applications

**Secrets Layer:**
- Purpose: Encrypted sensitive data (SSH keys, git signing keys, usernames)
- Location: `group_vars/all/personal-info.sops.yml`
- Contains: SOPS-encrypted YAML with Age recipient
- Depends on: Age private key at `~/.config/sops/age/keys.txt`
- Used by: Tool playbooks via Jinja2 templating

**Themes Layer:**
- Purpose: Consistent visual styling across tmux, starship, neovim
- Location: `themes/_color.yml`, `themes/_font.yml`, `themes/_style.yml`
- Contains: Ansible playbooks that modify deployed configs in-place
- Depends on: Deployed tool configurations
- Used by: `themesetting` zsh function, manual ansible-playbook calls

**Infrastructure Layer:**
- Purpose: Cloud resource provisioning (DigitalOcean droplets)
- Location: `infrastructure/`
- Contains: Pulumi TypeScript IaC
- Depends on: Pulumi CLI, DigitalOcean API token
- Used by: Manual infrastructure deployments

## Data Flow

**Bootstrap Flow:**

1. User runs bootstrap.sh (curl | bash)
2. Script detects OS (darwin/debian/arch)
3. User selects group memberships interactively
4. Script prompts for 1Password token and/or Age key
5. Dependencies installed (git, ansible)
6. Inventory file generated (localhost.yml)
7. ansible-playbook setup.yml executed

**Tool Installation Flow:**

1. setup.yml imports tool playbook
2. Tool playbook gathers facts (ansible_facts['os_family'])
3. OS-conditional tasks execute (Darwin/Debian/Archlinux)
4. Package installed via brew/apt/pacman/yay
5. Configuration files deployed (copy/template)
6. Shell integration added to ~/.zshrc
7. Post-install steps (Mason packages, service enable)

**Secrets Flow:**

1. Bootstrap configures Age key at `~/.config/sops/age/keys.txt`
2. Ansible loads SOPS-encrypted vars via community.sops plugin
3. Decrypted values available as variables (e.g., `{{ git_signing_key }}`)
4. Jinja2 templates interpolate secrets into configs
5. Templates render to target paths (e.g., `~/.gitconfig`)

**Theme Application Flow:**

1. User invokes `themesetting` function in zsh
2. fzf presents color/font/style options parsed from YAML
3. ansible-playbook runs with selected variable
4. Regex replacements update deployed configs (~/.tmux.conf, ~/.config/starship.toml, ~/.config/nvim/init.lua)
5. tmux reloaded automatically

**State Management:**
- Idempotency via `creates:` argument on shell tasks
- State checks via `stat:` module before expensive operations
- Changed status tracking for conditional reload tasks

## Key Abstractions

**OS Family Detection:**
- Purpose: Route tasks to correct package manager
- Examples: `tools/zsh/install_zsh.yml`, `tools/neovim/install_neovim.yml`
- Pattern: `when: ansible_facts['os_family'] == "Darwin|Debian|Archlinux"`

**Host Groups:**
- Purpose: Feature flags for optional tool sets
- Examples: `with_login_tools`, `with_gui_tools`, `with_browsers`, `with_ai_tools`
- Pattern: `hosts: with_ai_tools:&with_login_tools` (intersection)

**Shell Configuration Sourcing:**
- Purpose: Modular zsh configuration via ~/.config/zsh/*.zsh
- Examples: `tools/git/git.zsh`, `tools/fzf/fzf.zsh`
- Pattern: Copy to ~/.config/zsh/, add source line to ~/.zshrc

**Template Variants:**
- Purpose: OS/group-specific config rendering
- Examples: `tools/git/gitconfig.darwin.j2`, `tools/git/gitconfig.debian.j2`
- Pattern: Jinja2 includes for shared content, conditionals for variants

## Entry Points

**New Machine Setup:**
- Location: `bootstrap.sh`
- Triggers: Manual curl execution
- Responsibilities: Full environment provisioning from scratch

**Full Update (Local):**
- Location: `ansible-playbook setup.yml --connection=local --limit $(hostname -s)`
- Triggers: Manual execution
- Responsibilities: Update all tools on local machine

**Full Update (All Hosts):**
- Location: `setup-all.sh`
- Triggers: Manual execution
- Responsibilities: Run setup on localhost, then all remote hosts

**Single Tool Update:**
- Location: `ansible-playbook tools/<tool>/install_<tool>.yml --connection=local --limit $(hostname -s)`
- Triggers: Manual execution
- Responsibilities: Install/update specific tool only

**Theme Change:**
- Location: `themesetting` zsh function (defined in `tools/zsh/zshrc`)
- Triggers: Interactive shell command
- Responsibilities: Apply color/font/style changes across tools

## Error Handling

**Strategy:** Fail-fast with optional ignore

**Patterns:**
- `become: yes` required for apt/pacman (privilege escalation)
- `ignore_errors: yes` for optional operations (ssh-keyscan)
- `failed_when: false` for idempotent removal before add
- `creates:` argument prevents re-running completed shell commands
- `no_log: true` for secret-handling tasks

## Cross-Cutting Concerns

**Logging:** Ansible default output (task status, changed/ok/failed counts)

**Validation:**
- Linting via `ansible-lint setup.yml` and `ansible-lint tools/*/install_*.yml`
- Dry-run via `--check --diff` flags

**Authentication:**
- SSH keys deployed from 1Password service account
- Git commit signing via 1Password SSH agent (macOS)
- Age encryption for secrets at rest

---

*Architecture analysis: 2026-01-19*
