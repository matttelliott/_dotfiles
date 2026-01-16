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

### Run Locally (on macbookair)
```bash
ansible-playbook setup.yml --connection=local --limit macbookair
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
| `with_ai_tools` | AI tools (Claude Code) |

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

## Nerd Font / Powerline Characters

**IMPORTANT:** The tmux, starship, and neovim configs contain Nerd Font glyphs (Unicode Private Use Area: U+E0xx, U+F0xx, etc.). These characters are problematic for LLMs because they display as whitespace or render inconsistently.

**Files with special characters:**
- `tools/tmux/tmux.conf.j2`
- `tools/starship/starship.toml`
- `tools/neovim/nvim/init.lua`

**DO NOT edit these characters directly.** Instead, use Python scripts to modify them by code point:

```python
# Example: Generate a powerline arrow
POWERLINE_RIGHT = chr(0xE0B0)  #
POWERLINE_LEFT = chr(0xE0B2)   #
GIT_BRANCH = chr(0xE0A0)       #

# Find code point of existing character
char = ""  # paste character
print(f"U+{ord(char):04X}")
```

**For Lua (neovim)**, prefer `vim.fn.nr2char(0xe0b0)` over raw characters.

See README files in `tools/tmux/`, `tools/starship/`, and `tools/neovim/` for full character references.
