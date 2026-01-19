# Architecture

**Analysis Date:** 2026-01-19

## Pattern Overview

**Overall:** Ansible-based Configuration Management with Modular Tool Playbooks

**Key Characteristics:**
- Declarative infrastructure-as-code using Ansible playbooks
- Multi-OS support (macOS, Debian/Ubuntu, Arch Linux) via conditional tasks
- Modular per-tool installation with centralized orchestration
- Host group-based feature enablement (GUI tools, browsers, AI tools, etc.)
- Secrets management via SOPS with Age encryption and 1Password integration

## Layers

**Bootstrap Layer:**
- Purpose: Initial machine setup and Ansible installation
- Location: `bootstrap.sh`
- Contains: OS detection, interactive setup, inventory generation
- Depends on: System package managers (apt, pacman, brew)
- Used by: New machine provisioning

**Orchestration Layer:**
- Purpose: Coordinates tool installation order and manages shared setup
- Location: `setup.yml`
- Contains: Import statements for tool playbooks, pre/post setup tasks
- Depends on: Tool playbooks in `tools/*/install_*.yml`
- Used by: Main deployment via `ansible-playbook setup.yml`

**Tool Layer:**
- Purpose: Individual tool installation and configuration
- Location: `tools/<tool>/install_<tool>.yml`
- Contains: OS-specific installation tasks, config file deployment
- Depends on: Ansible facts, group_vars, OS package managers
- Used by: Orchestration layer, can also run standalone

**Configuration Layer:**
- Purpose: Tool-specific configuration files and shell integrations
- Location: `tools/<tool>/<config>.*`, `tools/<tool>/<tool>.zsh`
- Contains: Jinja2 templates, static configs, shell aliases
- Depends on: Tool layer for deployment
- Used by: End-user environment after deployment

**Variables Layer:**
- Purpose: Shared variables, defaults, and secrets
- Location: `group_vars/all/`
- Contains: `defaults.yml`, `personal-info.sops.yml` (encrypted)
- Depends on: SOPS/Age for decryption
- Used by: All playbooks via Ansible variable precedence

**Theming Layer:**
- Purpose: Coordinated color/style changes across tools
- Location: `themes/`
- Contains: `_color.yml`, `_font.yml`, `_style.yml`
- Depends on: Deployed tool configs (modifies them in-place)
- Used by: Interactive `themesetting` shell function

**Infrastructure Layer:**
- Purpose: Cloud resource provisioning
- Location: `infrastructure/`
- Contains: Pulumi TypeScript code for DigitalOcean
- Depends on: Pulumi CLI, cloud credentials
- Used by: Separate from Ansible deployment

## Data Flow

**Full Machine Provisioning:**

1. User runs `bootstrap.sh` on new machine
2. Bootstrap detects OS and installs base dependencies (git, ansible)
3. Bootstrap prompts for host groups and generates `localhost.yml`
4. Bootstrap runs `ansible-playbook setup.yml`
5. `setup.yml` imports each tool playbook in dependency order
6. Each tool playbook installs software and deploys configuration
7. Shell configs source tool-specific `.zsh` files on login

**Single Tool Update:**

1. User runs `ansible-playbook tools/<tool>/install_<tool>.yml --limit <host>`
2. Playbook gathers facts to determine OS
3. Conditional tasks execute based on `ansible_facts['os_family']`
4. Config files templated/copied to user home directory
5. Optional: zshrc updated to source tool's shell config

**Theme Change:**

1. User runs `themesetting` in terminal
2. Function parses available options from `themes/_color.yml`, etc.
3. User selects theme via fzf
4. Ansible playbook applies theme using regex replacements
5. User reloads tmux/restarts terminal

**State Management:**
- No persistent state - Ansible is idempotent
- Idempotency via `creates:` argument, `stat` checks, and `changed_when:`
- Secrets decrypted at runtime via SOPS vars plugin

## Key Abstractions

**Tool Module:**
- Purpose: Self-contained installation unit for one tool
- Examples: `tools/tmux/`, `tools/neovim/`, `tools/git/`
- Pattern: Directory contains `install_<tool>.yml` plus optional configs

**Host Group:**
- Purpose: Feature flags for machine capabilities
- Examples: `with_gui_tools`, `with_browsers`, `with_ai_tools`, `with_login_tools`
- Pattern: Defined in `inventory.yml`, hosts added to enable features

**OS Conditional:**
- Purpose: Platform-specific task execution
- Examples: `when: ansible_facts['os_family'] == "Darwin"`
- Pattern: `Darwin` (macOS), `Debian` (Debian/Ubuntu), `Archlinux` (Arch)

**Shell Integration:**
- Purpose: Tool-specific environment setup
- Examples: `tools/git/git.zsh`, `tools/starship/starship.zsh`
- Pattern: Copied to `~/.config/zsh/`, sourced via lineinfile in `~/.zshrc`

## Entry Points

**Bootstrap (new machine):**
- Location: `bootstrap.sh`
- Triggers: `curl | bash` from README
- Responsibilities: OS detection, dependency install, inventory generation, initial run

**Main Playbook:**
- Location: `setup.yml`
- Triggers: `ansible-playbook setup.yml --limit <host>`
- Responsibilities: Run all tool playbooks in correct order

**Per-Tool Playbook:**
- Location: `tools/<tool>/install_<tool>.yml`
- Triggers: `ansible-playbook tools/<tool>/install_<tool>.yml --limit <host>`
- Responsibilities: Install and configure single tool

**All Hosts Script:**
- Location: `setup-all.sh`
- Triggers: `./setup-all.sh`
- Responsibilities: Run setup.yml on localhost first, then all remote hosts

**Theme Selector:**
- Location: `tools/zsh/zshrc` (defines `themesetting` function)
- Triggers: `themesetting` command in terminal
- Responsibilities: Interactive theme selection and application

## Error Handling

**Strategy:** Fail fast with informative messages

**Patterns:**
- `become: yes` for privilege escalation where needed
- `creates:` argument for idempotent shell commands
- `ignore_errors: yes` for optional operations (e.g., host key scanning)
- `failed_when: false` for commands that may legitimately fail
- `no_log: true` for sensitive operations (secrets)
- `validate:` for config files (e.g., sudoers validation)

## Cross-Cutting Concerns

**Logging:** Ansible's built-in output; use `--check --diff` for preview

**Validation:**
- `ansible-lint` for playbook validation
- `visudo -cf %s` for sudoers file validation
- `creates:` checks prevent re-running completed tasks

**Authentication:**
- SSH keys managed via 1Password + SOPS
- `op read` fetches secrets at runtime
- Age key required for SOPS decryption

**Secrets:**
- Encrypted in `group_vars/all/personal-info.sops.yml`
- Age key stored at `~/.config/sops/age/keys.txt`
- 1Password service account token at `~/.config/op/service-account-token`

---

*Architecture analysis: 2026-01-19*
