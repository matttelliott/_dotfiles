# _dotfiles

Dotfiles and development environment management using Ansible. Supports macOS, Debian/Ubuntu, and Arch Linux with 78+ tools and applications.

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

### Update Existing Installation
```bash
ansible-playbook -i localhost.yml setup.yml
```

### Dry-run (Check Mode)
```bash
ansible-playbook -i localhost.yml setup.yml --check
```

### Install Specific Tool
```bash
ansible-playbook -i localhost.yml tools/<tool>/install_<tool>.yml
```

### Run on Remote Host
```bash
ansible-playbook setup.yml --limit myserver
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
