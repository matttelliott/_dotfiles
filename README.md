# _dotfiles

Dotfiles and development environment management using Ansible. Supports macOS, Debian/Ubuntu, and Arch Linux with 90+ tools and applications.

## Quick Start

### Bootstrap a New Machine

Run this on a fresh macOS, Debian, or Arch installation:

```bash
curl -fsSL https://raw.githubusercontent.com/matttelliott/_dotfiles/master/bootstrap.sh | bash
```

The interactive script will:
1. Detect your OS (macOS, Debian, or Arch)
2. Prompt you to select which groups to enable
3. Install dependencies (Xcode CLT + Homebrew on macOS, apt packages on Debian, pacman packages on Arch)
4. Clone the repo to `~/_dotfiles`
5. Generate your `localhost.yml` inventory
6. Run the Ansible playbook

### Update an Existing Installation

```bash
cd ~/_dotfiles
git pull
ansible-playbook -i localhost.yml setup.yml
```

### Run Specific Tools

```bash
ansible-playbook -i localhost.yml tools/neovim/install_neovim.yml
```

## Host Groups

Hosts are added to groups to control which tools are installed:

| Group | Description |
|-------|-------------|
| `macs` | macOS machines |
| `debian` | Debian/Ubuntu machines |
| `arch` | Arch Linux machines |
| `with_login_tools` | Git signing, SSH keys, cloud CLIs, dotfiles repo clone |
| `with_gui_tools` | WezTerm, 1Password, DBeaver |
| `with_browsers` | Chrome, Firefox, Brave, Arc, etc. |
| `with_ai_tools` | Claude Code |
| `with_nas` | Automount NAS shares from nas.home.lan |

## What's Included

### Shell & Terminal
- **zsh** - Z shell with case-insensitive completion
- **starship** - Cross-shell prompt with nerd font icons
- **wezterm** - GPU-accelerated terminal with TokyoNight theme
- **tmux** - Terminal multiplexer with vim-style navigation
- **mosh** - Mobile shell for roaming connections

### Programming Languages
- **node** - JavaScript runtime via nvm + prettierd, eslint_d, typescript
- **python** - Python via uv + ruff, black, isort
- **rust** - Rust via rustup + rustfmt, clippy, rust-analyzer
- **go** - Go + gofumpt, goimports, gopls
- **lua** - Lua + stylua

### Editor
- **neovim** - Kickstart.nvim config with:
  - TokyoNight colorscheme
  - Neo-tree file explorer (`<leader>e`)
  - Telescope fuzzy finder (`<leader>o`, `<leader>/`)
  - LSP support for TypeScript, Python, Go, Rust, Lua
  - prettierd/eslint_d formatting
  - gitsigns

### CLI Utilities
- **fd** - Fast file finder
- **fzf** - Fuzzy finder
- **ripgrep** - Fast grep alternative
- **bat** - cat with syntax highlighting
- **eza** - Modern ls replacement (aliased to `ls`, `l`)
- **jq** - JSON processor
- **sd** - sed alternative
- **lazygit** - Terminal UI for git (aliased to `gg`)

### Cloud & DevOps
- **awscli** - AWS CLI
- **gcloud** - Google Cloud CLI
- **doctl** - DigitalOcean CLI
- **gh** - GitHub CLI
- **pulumi** - Infrastructure as Code
- **1password_cli** - 1Password CLI

### Git
- Git config with SSH commit signing via 1Password
- Aliases: `g`, `gac`, `gacm`, `gl`, `glg`

### Network
- **nas** - Automount NAS shares via autofs (~/NAS/home)
- **wireguard** - VPN tunnel

### Browsers
Chrome, Chromium, Firefox, Brave, Arc, Edge, Opera, Vivaldi, LibreWolf, Waterfox, Zen, Orion, Min, Tor

## Shell Aliases

| Alias | Command |
|-------|---------|
| `q` | `exit` |
| `e` | `$EDITOR` (nvim) |
| `g` | `git status` |
| `gac` | `git add . && git commit` |
| `gacm` | `git add . && git commit -m` |
| `gl` | `git log --oneline` |
| `glg` | `git log --oneline --graph` |
| `gg` | `lazygit` |
| `ls` | `eza` |
| `l` | `eza -lah` |

## Neovim Keymaps

| Keymap | Action |
|--------|--------|
| `jk` / `kj` | Exit insert mode |
| `<leader>e` | Toggle Neo-tree |
| `<leader>E` | Reveal current file in Neo-tree |
| `<leader>o` | Find files (Telescope) |
| `<leader>/` | Grep project (Telescope) |
| `<leader>f` | Format buffer |

## Remote Machine Setup

1. Add the machine to `inventory.yml`:

```yaml
all:
  children:
    debian:
      hosts:
        myserver:
          ansible_host: 192.168.1.100
          ansible_user: matt

    with_login_tools:
      hosts:
        myserver:
```

2. Run the playbook:

```bash
ansible-playbook setup.yml --limit myserver
```

## Adding a New Tool

1. Create `tools/mytool/install_mytool.yml`:

```yaml
---
- name: Install mytool
  hosts: all
  gather_facts: true

  tasks:
    - name: Install mytool via Homebrew (macOS)
      shell: /opt/homebrew/bin/brew install mytool
      args:
        creates: /opt/homebrew/bin/mytool
      when: ansible_facts['os_family'] == "Darwin"

    - name: Install mytool via apt (Debian)
      apt:
        name: mytool
        state: present
      become: yes
      when: ansible_facts['os_family'] == "Debian"

    - name: Install mytool via pacman (Arch)
      pacman:
        name: mytool
        state: present
      become: yes
      when: ansible_facts['os_family'] == "Archlinux"
```

2. Import in `setup.yml`:

```yaml
- import_playbook: tools/mytool/install_mytool.yml
```

## Nerd Font / Powerline Characters

The tmux statusline, neovim statusline, and starship prompt use special glyphs from Nerd Fonts (Unicode Private Use Area). These characters require a patched font to display correctly.

**Key files with special characters:**
- `tools/tmux/tmux.conf.j2` - Powerline arrows, icons
- `tools/starship/starship.toml` - Powerline arrows, icons
- `tools/neovim/nvim/init.lua` - Statusline arrows, diagnostic icons

See the README in each tool directory for character code point references and editing instructions.

## Project Structure

```
_dotfiles/
├── bootstrap.sh          # Interactive bootstrap script
├── setup.yml             # Main playbook
├── localhost.yml         # Local machine inventory (generated)
├── inventory.yml         # Remote machines inventory
├── infrastructure/       # Pulumi IaC
└── tools/
    ├── arch/             # Arch-specific setup
    ├── debian/           # Debian-specific setup
    ├── macos/            # macOS-specific setup
    ├── yay/              # AUR helper for Arch
    └── <tool>/
        ├── install_<tool>.yml
        └── <tool>.zsh    # Shell config (optional)
```
