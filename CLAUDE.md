# _dotfiles

Dotfiles and development environment management using Ansible. Supports macOS, Debian/Ubuntu, and Arch Linux with 90+ tools and applications.

## Tech Stack

- **Ansible** - Primary automation framework for deployment and configuration
- **Bash** - Bootstrap script and shell configurations
- **TypeScript/Pulumi** - Infrastructure as Code in `/infrastructure`
- **YAML** - Ansible playbooks and configurations
- **Lua** - Neovim configuration

## Directory Structure

```
_dotfiles/
├── bootstrap.sh          # Interactive OS detection + setup script
├── setup.yml             # Main Ansible playbook
├── ansible.cfg           # Ansible configuration
├── localhost.yml         # Local machine inventory (generated)
├── inventory.yml         # Remote machines inventory
├── infrastructure/       # Pulumi IaC for DigitalOcean
└── tools/                # 78 tool directories
    └── <tool>/
        ├── install_<tool>.yml   # Ansible playbook (OS-specific)
        ├── <tool>.zsh           # Shell configuration (optional)
        └── <config>.*           # Tool configs (optional)
```

## Commands

### Bootstrap New Machine
```bash
curl -fsSL https://raw.githubusercontent.com/matttelliott/_dotfiles/master/bootstrap.sh | bash
```

### Run Locally
```bash
ansible-playbook setup.yml --connection=local --limit $(hostname -s)
```

### Dry-run (Check Mode)
```bash
ansible-playbook setup.yml --connection=local --limit $(hostname -s) --check --diff
```

### Install Specific Tool Locally
```bash
ansible-playbook tools/<tool>/install_<tool>.yml --connection=local --limit $(hostname -s)
```

### Development Workflow
1. Run in check mode with diff to preview changes
2. If issues, run `ansible-lint` to validate
3. Apply changes after review

### Run on All Hosts
```bash
./setup-all.sh
```
Runs `setup.yml` on localhost first, then all remote hosts. Passes any additional arguments to ansible-playbook.

### Run on Remote Host
```bash
ansible-playbook setup.yml --limit macbookair
ansible-playbook setup.yml --limit macmini
ansible-playbook setup.yml --limit desktop
```

### Lint Playbooks
```bash
ansible-lint setup.yml
ansible-lint tools/*/install_*.yml
```

## Host Groups

| Group | Description |
|-------|-------------|
| `macs` | macOS machines |
| `debian` | Debian/Ubuntu machines |
| `arch` | Arch Linux machines |
| `with_login_tools` | Git signing, SSH, cloud CLIs |
| `with_gui_tools` | GUI applications |
| `with_browsers` | Browser suite |
| `with_ai_tools` | AI tools (Claude Code, nvim-ai) |

## Ansible Patterns

### Per-Tool Playbook Structure
Each tool uses OS detection via `gather_facts`:
```yaml
- name: Install <tool>
  hosts: all
  gather_facts: true

  tasks:
    - name: macOS (Homebrew)
      when: ansible_facts['os_family'] == "Darwin"

    - name: Debian (apt)
      when: ansible_facts['os_family'] == "Debian"

    - name: Arch (pacman)
      when: ansible_facts['os_family'] == "Archlinux"
```

### Shell Configuration Pattern
Tools with shell config source their `<tool>.zsh` file in the zshrc.

## Code Style

- YAML: 2-space indentation
- Lua: 2-space indentation, single quotes (see `tools/neovim/nvim/.stylua.toml`)
- Shell: Use `shellcheck` for linting
- Playbooks: Use `ansible-lint` for validation
- Always use `become: yes` for package manager tasks on Linux
- Use `creates:` for idempotent Homebrew shell commands

## Claude Code Configuration

### Three-Layer Architecture Overview

Claude Code configuration follows a three-layer architecture, each with distinct ownership:

1. **User Layer (`~/.claude/`)** - Global defaults deployed by Ansible, applies to all repos
2. **Portable Layer (`~/.claude/<name>/`)** - Self-contained packages with their own installers (e.g., GSD)
3. **Repo Layer (`.claude/`)** - Project-specific config committed to each repository

### Layer Ownership Rules

| Layer | Location | Ownership | Examples |
|-------|----------|-----------|----------|
| User | `~/.claude/` | Ansible (this repo) | Global CLAUDE.md, base settings.json |
| Portable | `~/.claude/<name>/` | Package installer | GSD workflows, Context7 |
| Repo | `.claude/` | Per-repository | Project rules, custom commands |

### Current User-Level Structure

```
~/.claude/
├── settings.json         # Global settings (hooks, permissions)
├── CLAUDE.md             # Global instructions (if created)
├── commands/             # User-level slash commands
│   └── gsd/              # GSD namespace (from portable)
├── agents/               # User-level subagents
│   └── gsd-*.md          # GSD agents (from portable)
├── hooks/                # Hook scripts
│   └── *.js              # GSD hooks (from portable)
└── get-shit-done/        # GSD portable config
    ├── workflows/
    ├── templates/
    └── references/
```

### When to Use Each Layer

- **User:** Machine-wide defaults (permissions, common tools), shared across all projects
- **Portable:** Reusable workflow packages installed via npx, self-updating
- **Repo:** Project-specific rules, commands, hooks committed with source code

## Nerd Font / Powerline Characters

**IMPORTANT:** The tmux, starship, and neovim configs contain Nerd Font glyphs (Unicode Private Use Area: U+E0xx, U+F0xx, etc.). These characters are problematic for LLMs because they display as whitespace or render inconsistently.

**Files with special characters:**
- `tools/tmux/tmux.conf.j2`
- `tools/starship/starship.toml`
- `tools/neovim/nvim/init.lua`

**DO NOT edit these characters directly.** Use escape sequences by code point instead.

### Powerline Separator Code Points

| Style | Right | Left | Code Points |
|-------|-------|------|-------------|
| Angled | `` | `` | U+E0B0, U+E0B2 |
| Round | `` | `` | U+E0B4, U+E0B6 |

### Editing Approaches

**For Ansible playbooks** - Use `\uXXXX` escape sequences in variables:
```yaml
vars:
  arrow_right: "\uE0B0"
  round_right: "\uE0B4"
tasks:
  - ansible.builtin.replace:
      regexp: "{{ arrow_right }}"
      replace: "{{ round_right }}"
```

**For Lua (neovim)** - Use `vim.fn.nr2char()`:
```lua
local arrow_right = vim.fn.nr2char(0xe0b0)
```

**For Python** - Use `chr()`:
```python
POWERLINE_RIGHT = chr(0xE0B0)
```

### Reference Examples

See `themes/style_angle.yml` and `themes/style_round.yml` for complete working examples of replacing Nerd Font characters across tmux, starship, and neovim using Ansible.

See `README.md` section "Nerd Font / Powerline Characters" for full documentation.
