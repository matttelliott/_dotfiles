# Architecture

**Analysis Date:** 2026-01-18

## Pattern Overview

**Overall:** Modular Ansible Playbook Collection with Per-Tool Organization

**Key Characteristics:**

- Each tool is self-contained in its own directory with installation playbook
- Main orchestrator playbook (`setup.yml`) imports all tool playbooks in dependency order
- OS detection at runtime allows single codebase for macOS, Debian, and Arch Linux
- Host groups control which tools get installed on which machines
- Shell configuration is composable via sourced `.zsh` files
- Jinja2 templates enable OS-specific and host-specific configuration variants

## Layers

**Bootstrap Layer:**

- Purpose: Initial machine setup before Ansible is available
- Location: `bootstrap.sh`
- Contains: OS detection, dependency installation, inventory generation, 1Password/Age key setup
- Depends on: curl, bash
- Used by: New machine setup (manual execution)

**Orchestration Layer:**

- Purpose: Coordinate tool installation in correct order
- Location: `setup.yml`
- Contains: Import statements for all tool playbooks, pre/post setup tasks (Homebrew update, apt cache, sleep management)
- Depends on: Ansible, tool playbooks
- Used by: `setup-all.sh`, direct ansible-playbook invocation

**Tool Layer:**

- Purpose: Install and configure individual tools
- Location: `tools/<tool>/install_<tool>.yml`
- Contains: OS-specific installation tasks, configuration deployment, shell integration
- Depends on: Package managers (Homebrew, apt, pacman, yay), base tools (zsh, git)
- Used by: Orchestration layer, direct playbook execution for single-tool updates

**Configuration Layer:**

- Purpose: Store tool configurations and templates
- Location: `tools/<tool>/*.j2`, `tools/<tool>/*.zsh`, `tools/<tool>/config.*`
- Contains: Jinja2 templates, shell aliases/functions, application configs
- Depends on: Ansible template/copy modules
- Used by: Tool playbooks

**Variable Layer:**

- Purpose: Store shared configuration and secrets
- Location: `group_vars/all/defaults.yml`, `group_vars/all/personal-info.sops.yml`
- Contains: Git user info, SSH keys, GitHub username, default values
- Depends on: SOPS/Age for encrypted values
- Used by: All playbooks via Ansible variable precedence

**Inventory Layer:**

- Purpose: Define target hosts and group membership
- Location: `inventory.yml` (remote), `localhost.yml` (local, generated)
- Contains: Host definitions, group assignments, connection settings
- Depends on: None
- Used by: Ansible for targeting

**Theming Layer:**

- Purpose: Coordinate visual theming across tools
- Location: `themes/_color.yml`, `themes/_style.yml`, `themes/_font.yml`
- Contains: Ansible playbooks for color schemes, powerline separators, fonts
- Depends on: Deployed tool configs (tmux, starship, neovim)
- Used by: `themesetting` zsh function

**Infrastructure Layer:**

- Purpose: Cloud resource provisioning
- Location: `infrastructure/`
- Contains: Pulumi TypeScript IaC for DigitalOcean
- Depends on: Pulumi, DigitalOcean provider
- Used by: Manual execution for cloud infrastructure

## Data Flow

**Bootstrap Flow:**

1. User runs `bootstrap.sh` (can be piped from curl)
2. Script detects OS (darwin/debian/arch)
3. Prompts for host group selection (login_tools, gui_tools, browsers, ai_tools)
4. Sets up 1Password service account token (optional)
5. Fetches Age key from 1Password or prompts for manual entry
6. Installs OS-specific dependencies (Xcode CLT, Homebrew, apt packages)
7. Clones dotfiles repository
8. Generates `localhost.yml` inventory based on selections
9. Runs `ansible-playbook setup.yml`

**Setup Flow:**

1. `setup.yml` runs pre-tasks (update package caches, disable macOS sleep)
2. OS-specific base playbooks run (macos, debian, arch)
3. Tool playbooks execute in dependency order (shell first, languages, then apps)
4. Dotfiles repo is cloned/updated mid-run (after SSH is configured)
5. Remaining tools install
6. Post-tasks run (re-enable macOS sleep)

**Tool Installation Flow:**

1. Playbook gathers facts (`ansible_facts['os_family']`)
2. Conditional tasks execute based on OS
3. Package installed via appropriate manager
4. Configuration files deployed (template or copy)
5. Shell integration added to `~/.zshrc` via lineinfile
6. Post-install hooks run (e.g., reload tmux config)

**State Management:**

- Ansible manages idempotency via `creates:` parameter, `state: present`, and `changed_when`
- Secrets decrypted at runtime via SOPS/Age integration
- No persistent state file - Ansible checks actual system state each run

## Key Abstractions

**Tool Directory:**

- Purpose: Encapsulate everything for a single tool
- Examples: `tools/zsh/`, `tools/tmux/`, `tools/neovim/`
- Pattern: Each contains `install_<tool>.yml` and optional config files

**Host Groups:**

- Purpose: Control which tools install on which machines
- Examples: `with_login_tools`, `with_gui_tools`, `with_browsers`, `with_ai_tools`, `with_nas`
- Pattern: Used in playbook `hosts:` directive with intersection (`&`) for multi-group requirements

**OS Family Detection:**

- Purpose: Single playbook supports multiple operating systems
- Examples: `when: ansible_facts['os_family'] == "Darwin"`, `"Debian"`, `"Archlinux"`
- Pattern: Conditional tasks for each supported OS

**Shell Configuration Sourcing:**

- Purpose: Modular shell customization per tool
- Examples: `tools/git/git.zsh`, `tools/fzf/fzf.zsh`
- Pattern: Playbook adds `source ~/.config/zsh/<tool>.zsh` to `~/.zshrc`

**Jinja2 Templates:**

- Purpose: Generate OS-specific or user-specific configuration
- Examples: `tools/git/gitconfig.darwin.j2`, `tools/ssh/config.j2`, `tools/tmux/tmux.conf.j2`
- Pattern: Playbook uses `template:` module to render with variables

## Entry Points

**`bootstrap.sh`:**

- Location: `/home/matt/_dotfiles/bootstrap.sh`
- Triggers: Manual execution on new machines
- Responsibilities: Initial setup, inventory generation, first Ansible run

**`setup.yml`:**

- Location: `/home/matt/_dotfiles/setup.yml`
- Triggers: `ansible-playbook setup.yml`, `setup-all.sh`, bootstrap completion
- Responsibilities: Full system configuration, tool installation in order

**`setup-all.sh`:**

- Location: `/home/matt/_dotfiles/setup-all.sh`
- Triggers: Manual execution for fleet-wide updates
- Responsibilities: Run setup.yml on localhost first, then all remote hosts

**`tools/<tool>/install_<tool>.yml`:**

- Location: `/home/matt/_dotfiles/tools/*/install_*.yml`
- Triggers: Import from setup.yml, direct execution for single-tool updates
- Responsibilities: Install and configure one tool

**`themes/_*.yml`:**

- Location: `/home/matt/_dotfiles/themes/`
- Triggers: `themesetting` zsh function, direct ansible-playbook execution
- Responsibilities: Apply visual themes across tmux, starship, neovim

## Error Handling

**Strategy:** Fail fast with clear error messages, use `ignore_errors` sparingly

**Patterns:**

- `become: yes` for privileged operations, Ansible handles privilege escalation failures
- `creates:` parameter prevents re-running shell commands unnecessarily
- `when:` conditions skip inapplicable tasks (wrong OS, missing dependencies)
- `ignore_errors: yes` used for optional features (e.g., adding SSH known hosts)
- `failed_when: false` for tasks where failure is acceptable (MCP server updates)
- SOPS decryption failures halt playbook (secrets are required for login hosts)

## Cross-Cutting Concerns

**Logging:** Ansible default output, verbose mode via `-v` flags

**Validation:** `ansible-lint` for playbook validation, no automated pre-commit hooks

**Authentication:**

- 1Password service account for secrets at bootstrap
- Age/SOPS for encrypted variables in repository
- SSH key deployment for cross-host access

**Idempotency:** Core Ansible principle - all tasks designed to be re-runnable safely

---

_Architecture analysis: 2026-01-18_
