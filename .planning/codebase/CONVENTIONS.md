# Coding Conventions

**Analysis Date:** 2026-01-18

## Naming Patterns

**Files:**

- Ansible playbooks: `install_<tool>.yml` in `tools/<tool>/`
- Shell configurations: `<tool>.zsh` in `tools/<tool>/`
- Jinja2 templates: `<name>.j2` (e.g., `gitconfig.darwin.j2`, `tmux.conf.j2`)
- SOPS encrypted files: `*.sops.yml`
- Infrastructure: `index.ts` for Pulumi entry point

**Directories:**

- Tool directories: lowercase with hyphens (e.g., `1password_cli`, `build-essential`, `chrome_canary`)
- Underscores preferred over hyphens for multi-word tool names

**Variables (Ansible):**

- Snake_case for all variable names (e.g., `git_user_name`, `ssh_public_key`)
- Register variables describe content (e.g., `docker_ce_check`, `op_ssh_key`)
- Facts accessed via `ansible_facts['key']` pattern

**Variables (Shell):**

- UPPERCASE for environment variables (e.g., `DOTFILES`, `FZF_DEFAULT_OPTS`)
- lowercase for local variables in functions

**Variables (Lua):**

- Snake_case for local variables (e.g., `arrow_right`, `have_nerd_font`)
- Vim globals use `vim.g.` prefix

## Code Style

**Formatting:**

- YAML: 2-space indentation
- Lua: 2-space indentation, configured in `tools/neovim/nvim/.stylua.toml`
- Shell: Standard bash formatting
- TypeScript: Default TypeScript formatting

**Lua (Neovim) specifics from `.stylua.toml`:**

```toml
column_width = 160
line_endings = "Unix"
indent_type = "Spaces"
indent_width = 2
quote_style = "AutoPreferSingle"
call_parentheses = "None"
```

**Linting:**

- Ansible: Use `ansible-lint` for validation
- Shell: Use `shellcheck` for bash scripts
- No ESLint/Prettier configured (infrastructure code is minimal)

## Ansible Playbook Structure

**Standard playbook header:**

```yaml
---
- name: Install <tool>
  hosts: all
  gather_facts: true

  tasks:
    - name: Descriptive task name (OS)
      <module>: <params>
      become: yes # Required for Linux package managers
      when: ansible_facts['os_family'] == "<family>"
```

**OS family detection patterns:**

```yaml
# macOS
when: ansible_facts['os_family'] == "Darwin"

# Debian/Ubuntu
when: ansible_facts['os_family'] == "Debian"

# Arch Linux
when: ansible_facts['os_family'] == "Archlinux"

# Multiple Linux families
when: ansible_facts['os_family'] in ["Debian", "Archlinux"]
```

**Host group targeting:**

```yaml
# All hosts
hosts: all

# Specific OS family
hosts: macs
hosts: debian
hosts: arch

# Feature groups
hosts: with_login_tools
hosts: with_gui_tools
hosts: with_browsers
hosts: with_ai_tools
```

## Idempotency Patterns

**Homebrew shell commands require `creates:`:**

```yaml
- name: Install tmux via Homebrew
  shell: /opt/homebrew/bin/brew install tmux
  args:
    creates: /opt/homebrew/bin/tmux
  when: ansible_facts['os_family'] == "Darwin"
```

**Pre-check with stat for complex installs:**

```yaml
- name: Check if Neovim is installed (Debian)
  stat:
    path: /usr/local/bin/nvim
  register: nvim_check
  when: ansible_facts['os_family'] == "Debian"

- name: Download and install Neovim from GitHub (Debian)
  shell: |
    curl -LO https://...
  when: ansible_facts['os_family'] == "Debian" and not nvim_check.stat.exists
```

**Changed detection for git commands:**

```yaml
- name: Update dotfiles repo
  command: git pull --ff-only
  args:
    chdir: ~/_dotfiles
  register: git_pull
  changed_when: "'Already up to date' not in git_pull.stdout"
```

## Import Organization

**Ansible playbook imports in `setup.yml`:**

1. OS-specific setup (sudoers, package cache updates)
2. Base tools (curl, unzip, zsh)
3. Secrets management (1password_cli, ssh, git)
4. Programming languages (python, node, rust, go, lua)
5. Shell environment (starship, tmux, neovim)
6. CLI utilities (fd, ripgrep, fzf, jq, etc.)
7. Cloud/DevOps tools (docker, kubectl, helm)
8. GUI applications (browsers, desktop apps)

**Shell script sourcing pattern:**

```bash
# Conditional sourcing based on OS
if [[ -f /opt/homebrew/share/... ]]; then
  source /opt/homebrew/share/...
elif [[ -f /usr/share/... ]]; then
  source /usr/share/...
fi
```

## Error Handling

**Ansible error handling:**

```yaml
# Ignore expected failures
ignore_errors: yes

# Fail silently and check later
failed_when: false
changed_when: false

# Continue on unreachable hosts
- name: Add host keys to known_hosts
  shell: ssh-keyscan -H {{ item }}.home.lan >> ~/.ssh/known_hosts
  ignore_errors: yes
```

**Shell error handling:**

```bash
#!/bin/bash
set -e  # Exit on first error

# Or handle specific failures
command || true  # Continue on failure
```

## Shell Configuration Pattern

**Installing shell config for a tool:**

```yaml
- name: Create zsh config directory
  file:
    path: ~/.config/zsh
    state: directory

- name: Install <tool> zsh config
  copy:
    src: <tool>.zsh
    dest: ~/.config/zsh/<tool>.zsh

- name: Source <tool> config in zshrc
  lineinfile:
    path: ~/.zshrc
    line: "source ~/.config/zsh/<tool>.zsh"
    create: yes
```

## Template Patterns

**Jinja2 template includes:**

```jinja2
{% include 'gitconfig.base.j2' %}
{% include 'gitconfig.personal.j2' %}
{% if git_signing_key %}
[user]
  signingkey = {{ git_signing_key }}
{% endif %}
```

**Conditional content:**

```jinja2
{% if 'with_login_tools' in group_names %}
  # Full config
{% else %}
  # Minimal config
{% endif %}
```

## Secrets Management

**SOPS encrypted variables:**

- Location: `group_vars/all/personal-info.sops.yml`
- Encrypted with Age key
- Decrypted at runtime by Ansible SOPS plugin
- Variable names: `git_user_name`, `git_user_email`, `git_signing_key`, etc.

**1Password CLI integration:**

```yaml
- name: Fetch SSH private key from 1Password
  shell: |
    export OP_SERVICE_ACCOUNT_TOKEN=$(cat ~/.config/op/service-account-token)
    {{ op_cli_path.stdout }} read "{{ op_ssh_private_key_ref }}"
  register: op_ssh_key
  no_log: true # Hide sensitive output
```

## Nerd Font / Powerline Characters

**Critical:** Files with Nerd Font glyphs require special handling. Do NOT edit these characters directly.

**Affected files:**

- `tools/tmux/tmux.conf.j2`
- `tools/starship/starship.toml`
- `tools/neovim/nvim/init.lua`

**Use escape sequences by code point:**

| Style  | Right | Left | Code Points    |
| ------ | ----- | ---- | -------------- |
| Angled |       |      | U+E0B0, U+E0B2 |
| Round  |       |      | U+E0B4, U+E0B6 |

**For Ansible:**

```yaml
vars:
  arrow_right: "\uE0B0"
  round_right: "\uE0B4"
```

**For Lua:**

```lua
local arrow_right = vim.fn.nr2char(0xe0b0)
```

## Comments

**Ansible playbook comments:**

```yaml
---
# Docker Installation
#
# macOS: Uses Colima + docker CLI (free alternative to Docker Desktop)
# Linux: Uses docker-ce (Docker Community Edition)

- name: Install Docker
  ...
```

**Shell comments:**

```bash
# Eza configuration - TokyoNight Storm theme
alias ls='eza'

# Colors: directories=blue, executables=green, symlinks=cyan
export EZA_COLORS="..."
```

**Lua comments:**

```lua
-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are loaded
```

## Function/Task Design

**Task naming:**

- Use descriptive names with OS suffix when conditional
- Format: `<Action> <thing> via <method> (<OS>)`
- Examples:
  - `Install git via apt (Debian)`
  - `Install tmux via Homebrew`
  - `Create zsh config directory`

**Shell aliases:**

- Short, memorable aliases
- Document purpose in comments
- Examples from `tools/git/git.zsh`:

```bash
alias g='git status'
alias gac='git add . && git commit'
alias gacm='git add . && git commit -m'
```

## Module Preferences

**Prefer Ansible modules over shell commands:**

```yaml
# Good - use apt module
- name: Install git via apt (Debian)
  apt:
    name: git
    state: present
  become: yes

# Avoid unless necessary
- name: Install git via apt (Debian)
  shell: apt install -y git
  become: yes
```

**When shell is required:**

- Complex multi-step operations
- Commands without Ansible modules
- Always include `creates:` or `changed_when:` for idempotency

---

_Convention analysis: 2026-01-18_
