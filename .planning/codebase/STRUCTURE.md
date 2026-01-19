# Codebase Structure

**Analysis Date:** 2026-01-19

## Directory Layout

```
_dotfiles/
├── bootstrap.sh              # Interactive setup for new machines
├── setup.yml                 # Main Ansible playbook (imports all tools)
├── setup-all.sh              # Run setup on local + all remote hosts
├── ansible.cfg               # Ansible configuration
├── inventory.yml             # Remote host definitions
├── localhost.yml             # Local machine inventory (generated)
├── requirements.yml          # Ansible Galaxy dependencies
├── CLAUDE.md                 # AI assistant instructions
├── README.md                 # Project documentation
├── .sops.yaml                # SOPS encryption config
├── group_vars/               # Ansible variables
│   └── all/                  # Variables for all hosts
│       ├── defaults.yml      # Default values (public)
│       └── personal-info.sops.yml  # Encrypted secrets
├── tools/                    # 101 tool directories
│   └── <tool>/               # One directory per tool
│       ├── install_<tool>.yml    # Ansible playbook
│       ├── <tool>.zsh            # Shell config (optional)
│       └── <config>.*            # Tool configs (optional)
├── themes/                   # Coordinated theming system
│   ├── _color.yml            # Color scheme application
│   ├── _font.yml             # Font changes
│   └── _style.yml            # Powerline style changes
├── infrastructure/           # Pulumi IaC (separate from Ansible)
│   ├── index.ts              # DigitalOcean droplet definition
│   ├── Pulumi.yaml           # Pulumi project config
│   └── Pulumi.dev.yaml       # Dev stack config
├── .claude/                  # Claude Code repo-level config
│   ├── settings.local.json   # Local settings
│   ├── commands/             # Slash commands
│   ├── rules/                # Instruction rules
│   └── hooks/                # Event hooks
├── .ansible/                 # Ansible runtime (local collections)
│   ├── collections/
│   ├── roles/
│   └── modules/
└── .planning/                # GSD planning documents
    └── codebase/             # Codebase analysis (this file)
```

## Directory Purposes

**tools/**
- Purpose: Contains all installable tools and their configurations
- Contains: 101 tool directories, each self-contained
- Key files: `install_<tool>.yml` (required), `<tool>.zsh` (optional), config files

**group_vars/all/**
- Purpose: Shared Ansible variables available to all playbooks
- Contains: `defaults.yml` (public defaults), `personal-info.sops.yml` (encrypted secrets)
- Key files: Variables like `git_user_name`, `git_user_email`, `ssh_public_key`

**themes/**
- Purpose: Coordinated theme management across multiple tools
- Contains: Ansible playbooks that modify deployed configs via regex
- Key files: `_color.yml` (8 color schemes), `_font.yml`, `_style.yml`

**infrastructure/**
- Purpose: Cloud resource provisioning (separate from dotfiles)
- Contains: Pulumi TypeScript project for DigitalOcean
- Key files: `index.ts` defines a Debian droplet

**.claude/**
- Purpose: Claude Code AI assistant configuration for this repository
- Contains: Scaffold directories for commands, rules, hooks
- Key files: `settings.local.json`

## Key File Locations

**Entry Points:**
- `bootstrap.sh`: New machine setup (curl | bash)
- `setup.yml`: Main playbook with all tool imports
- `setup-all.sh`: Multi-host deployment script

**Configuration:**
- `ansible.cfg`: Sets inventory, collections path, SOPS plugin
- `inventory.yml`: Remote host definitions with groups
- `localhost.yml`: Generated local inventory (not committed)
- `.sops.yaml`: Age encryption recipients

**Core Logic:**
- `setup.yml`: Tool import order, pre/post tasks (cache updates, sleep management)
- `tools/zsh/install_zsh.yml`: Shell setup, defines `$DOTFILES`
- `tools/git/install_git.yml`: Git config templates per OS
- `tools/ssh/install_ssh.yml`: SSH key deployment from 1Password

**Testing:**
- No test framework - use `--check --diff` mode
- `ansible-lint` for validation

## Naming Conventions

**Files:**
- Playbooks: `install_<tool>.yml` (kebab-case tool name)
- Shell configs: `<tool>.zsh`
- Templates: `<name>.j2` (Jinja2 templates)
- Static configs: Various (tool-specific naming)

**Directories:**
- Tools: lowercase, hyphenated for multi-word (e.g., `claude-code`, `chrome_canary`)
- System dirs: dot-prefixed (`.ansible/`, `.claude/`, `.planning/`)

**Ansible Tasks:**
- Name format: `<Action> <thing> [via <method>] [(<OS>)]`
- Examples: `Install zsh via apt (Debian)`, `Install tmux config`

**Variables:**
- Snake_case: `git_user_name`, `ssh_public_key`
- Boolean groups: `with_<feature>` (e.g., `with_gui_tools`)

## Where to Add New Code

**New Tool:**
1. Create directory: `tools/<tool>/`
2. Create playbook: `tools/<tool>/install_<tool>.yml`
3. Add import to `setup.yml` in correct position (consider dependencies)
4. Optional: Add `<tool>.zsh` for shell config
5. Optional: Add config files/templates

**Tool Playbook Template:**
```yaml
---
- name: Install <tool>
  hosts: all  # Or specific group like with_gui_tools
  gather_facts: true

  tasks:
    - name: Install via Homebrew (macOS)
      shell: /opt/homebrew/bin/brew install <tool>
      args:
        creates: /opt/homebrew/bin/<tool>
      when: ansible_facts['os_family'] == "Darwin"

    - name: Install via apt (Debian)
      apt:
        name: <tool>
        state: present
      become: yes
      when: ansible_facts['os_family'] == "Debian"

    - name: Install via pacman (Arch)
      pacman:
        name: <tool>
        state: present
      become: yes
      when: ansible_facts['os_family'] == "Archlinux"
```

**New Shell Integration:**
1. Create `tools/<tool>/<tool>.zsh` with aliases/functions
2. Add task in playbook to copy to `~/.config/zsh/<tool>.zsh`
3. Add task to source in zshrc via lineinfile

**New Theme:**
- Add color definition to `themes/_color.yml` under `colors:` dict
- Include: name, bg, bg_hl, fg, fg_dim, fg_bright, accent, accent_dark, cyan, green, red, magenta
- Include tool-specific names: wezterm, nvim, bat

**New Host Group:**
1. Add group definition to `inventory.yml`
2. Add hosts to group
3. Use in playbooks with `hosts: <group>` or `when: '<group>' in group_names`

**Utilities:**
- Shared shell functions: Add to `tools/zsh/zshrc`
- Tool-specific: Add to `tools/<tool>/<tool>.zsh`

## Special Directories

**.ansible/**
- Purpose: Local Ansible runtime (collections, roles, modules)
- Generated: Yes (by ansible-galaxy)
- Committed: No (in .gitignore)

**.planning/**
- Purpose: GSD planning and codebase analysis documents
- Generated: Yes (by GSD commands)
- Committed: Yes

**infrastructure/**
- Purpose: Pulumi IaC for cloud resources
- Generated: No
- Committed: Yes (but node_modules/ ignored)

**tools/neovim/nvim/**
- Purpose: Complete Neovim configuration
- Contains: Kickstart-based config with custom plugins
- Committed: Yes (copied to ~/.config/nvim/)

## Tool Categories

**Package Managers:** homebrew, yay

**Languages:** node, python, rust, go, lua

**Shell/Terminal:** zsh, tmux, starship, wezterm

**Editor:** neovim, nvim-ai

**CLI Utilities:** fd, ripgrep, fzf, jq, bat, eza, htop, btop

**Git/Dev:** git, lazygit, lazydocker, docker, gh

**Cloud/K8s:** kubectl, k9s, helm, kubectx, doctl, awscli, gcloud, pulumi

**Security:** ssh, age, sops, 1password, 1password_cli

**Browsers:** chrome, firefox, brave, vivaldi, opera, arc, edge, tor, librewolf, zen, orion

**AI Tools:** claude-code, claude-desktop, chatgpt-desktop, codex, nvim-ai

**System (OS-specific):** macos, debian, arch, sudoers, build-essential

---

*Structure analysis: 2026-01-19*
