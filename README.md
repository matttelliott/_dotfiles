# Dotfiles Ansible

Automated dotfiles management using Ansible with cross-platform support for Debian, macOS, and Arch Linux.

## 🎯 Features

- **Cross-Platform**: Supports Debian/Ubuntu, macOS, and Arch Linux
- **Idempotent**: Safe to run multiple times
- **Modular**: Role-based structure for easy customization
- **Control Node**: Deploy to local machine or remote hosts
- **Version Controlled**: Git repository for tracking changes

## 🛠️ What's Included

### Tools
- **Zsh**: Modern shell with default configuration
- **Tmux**: Terminal multiplexer with [matttelliott's config](https://github.com/matttelliott/dotfiles/blob/master/tmux/.tmux.conf)
- **Neovim**: Modern Vim with [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim) configuration
- **GitHub CLI (gh)**: Official GitHub command-line tool for repository management

### Base Packages
- Git, curl, wget, vim
- Build essentials (gcc, make, cmake)
- System utilities (htop, tree, unzip)

## 🚀 Quick Start

### Local Installation

1. Clone the repository:
```bash
git clone https://github.com/YOUR_USERNAME/dotfiles-ansible.git ~/.dotfiles
cd ~/.dotfiles
```

2. Run the installation:
```bash
./scripts/install.sh
```

3. Restart your shell:
```bash
exec zsh
```

### Remote Deployment

This repository is configured as an Ansible control node. Deploy to remote hosts:

```bash
# 1. Add remote hosts to inventory/hosts.yml
vim inventory/hosts.yml

# 2. Copy SSH key to remote host
ssh-copy-id -i ~/.ssh/ansible_control.pub user@remote-host

# 3. Deploy dotfiles
ansible-playbook deploy.yml --ask-become-pass
```

See [docs/CONTROL_NODE.md](docs/CONTROL_NODE.md) for detailed control node documentation.

## 📋 Usage

### Ansible Playbooks

**Local installation:**
```bash
ansible-playbook site.yml --ask-become-pass
```

**Remote deployment:**
```bash
# Deploy to all hosts
ansible-playbook deploy.yml --ask-become-pass

# Deploy to specific group
ansible-playbook deploy.yml --limit dev_servers --ask-become-pass

# Deploy only specific tools
ansible-playbook deploy.yml --tags zsh,tmux --ask-become-pass
```

### Available Tags

- `base` / `packages` - Base system packages
- `zsh` / `shell` - Zsh shell configuration
- `tmux` - Tmux configuration
- `neovim` / `nvim` / `editor` - Neovim setup
- `gh-cli` / `github` / `git` - GitHub CLI setup
- `doctl` / `digitalocean` / `cloud` - DigitalOcean CLI setup

## 🎨 Customization

### Local Overrides

Create local configuration files to customize your environment:

- `~/.zshrc` - Custom Zsh config
- `~/.tmux.conf.local` - Custom Tmux config
- `~/.config/nvim/lua/custom/` - Custom Neovim config

### Variables

#### Zsh
Uses default Zsh configuration. Customize by adding your own `~/.zshrc` file.

#### Tmux
Uses configuration from [matttelliott's dotfiles](https://github.com/matttelliott/dotfiles/blob/master/tmux/.tmux.conf):
- Prefix: `Ctrl+a`
- Vi-mode keybindings
- Vim-style pane navigation (h/j/k/l)
- Mouse support enabled

#### Neovim
Uses [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim) as base.
Customize by adding files to `~/.config/nvim/lua/custom/`

## ⌨️ Key Bindings

### Tmux

- **Prefix**: `Ctrl+a`
- **Split vertical**: `Prefix` + `%`
- **Split horizontal**: `Prefix` + `"`
- **Navigate panes**: `Prefix` + `h/j/k/l` (Vim-style)
- **Resize panes**: `Prefix` + `Ctrl+h/j/k/l`
- **Previous/Next window**: `Prefix` + `Ctrl+p/n`
- **Copy mode**: `Prefix` + `Escape`
- **Mouse support**: Enabled

### Neovim

See [kickstart.nvim documentation](https://github.com/nvim-lua/kickstart.nvim) for keybindings.
- **Leader key**: `Space`
- LSP features enabled out of the box
- Use `:Telescope` for fuzzy finding

## 📂 Directory Structure

```
dotfiles-ansible/
├── ansible.cfg           # Ansible configuration
├── site.yml             # Local installation playbook
├── deploy.yml           # Remote deployment playbook
├── inventory/
│   ├── hosts.yml       # Remote hosts inventory
│   ├── group_vars/     # Group-specific variables
│   └── host_vars/      # Host-specific variables
├── roles/
│   ├── base-packages/  # System packages
│   ├── zsh/            # Zsh with Zinit
│   ├── tmux/           # Tmux configuration
│   ├── neovim/         # Neovim with kickstart.nvim
│   ├── gh-cli/         # GitHub CLI
│   └── doctl/          # DigitalOcean CLI
├── scripts/
│   └── install.sh      # Bootstrap script
└── docs/
    ├── CONTROL_NODE.md # Control node documentation
    └── IMPLEMENTATION.md # Implementation details
```

## 🔧 Control Node Features

This repository is configured as an Ansible control node:

- ✅ SSH key generated: `~/.ssh/ansible_control`
- ✅ Inventory structure ready
- ✅ Remote deployment playbook
- ✅ Group and host variable support

### Quick Control Node Commands

```bash
# Test connectivity
ansible all -m ping

# Check disk space on all hosts
ansible all -m shell -a "df -h"

# Deploy to specific host
ansible-playbook deploy.yml --limit hostname --ask-become-pass
```

See [docs/CONTROL_NODE.md](docs/CONTROL_NODE.md) for comprehensive documentation.

## 🐛 Troubleshooting

### Ansible Not Found

Install Ansible manually:

**Debian/Ubuntu:**
```bash
sudo apt-get update
sudo apt-get install -y ansible git
```

**macOS:**
```bash
brew install ansible
```

**Arch Linux:**
```bash
sudo pacman -S ansible
```

### SSH Key Issues

```bash
# Generate new control node key
ssh-keygen -t ed25519 -C "ansible-control@dotfiles" -f ~/.ssh/ansible_control

# Copy to remote host
ssh-copy-id -i ~/.ssh/ansible_control.pub user@remote-host
```

## 📝 Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| Debian 12+ | ✅ Tested | Primary development platform |
| Ubuntu 20.04+ | ✅ Supported | LTS versions recommended |
| macOS 12+ | ✅ Supported | Requires Homebrew |
| Arch Linux | ✅ Supported | Rolling release |

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test locally with `ansible-playbook site.yml --check`
5. Submit a pull request

## 📄 License

MIT License - feel free to use and modify

## 🔗 Resources

- [Ansible Documentation](https://docs.ansible.com/)
- [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim)
- [Zinit Plugin Manager](https://github.com/zdharma-continuum/zinit)
- [matttelliott's dotfiles](https://github.com/matttelliott/dotfiles)

---

**Made with ❤️ using Ansible**
