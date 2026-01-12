# dotphiles

Dotfiles and development environment management using Ansible. Supports macOS and Debian-based systems with 50+ tools and applications.

## Quick Start

### Bootstrap a New macOS Machine

Run the bootstrap script on a fresh macOS installation:

```bash
git clone https://github.com/matttelliott/dotphiles.git
cd dotphiles
./bootstrap.sh
```

The script will:
1. Install Xcode Command Line Tools
2. Install Homebrew
3. Install Ansible
4. Run the full setup playbook

### Set Up Against Localhost

For running against your local machine (useful after initial bootstrap or for updates):

```bash
ansible-playbook -i localhost.yml setup.yml
```

Or to run specific tools only:

```bash
ansible-playbook -i localhost.yml tools/neovim/install_neovim.yml
```

### Set Up Other Machines in the Inventory

1. Add the machine to `inventory.yml`:

```yaml
all:
  children:
    debian:  # or macs:
      hosts:
        myserver:
          ansible_host: 192.168.1.100
          ansible_user: matt

    with_login_tools:
      hosts:
        myserver:

    # Add to other groups as needed:
    # with_gui_tools, with_browsers, with_ai_tools
```

2. Run the playbook against the inventory:

```bash
ansible-playbook setup.yml
```

Or target specific hosts:

```bash
ansible-playbook setup.yml --limit myserver
```

### Set Up Debian Machines

For Debian systems, ensure SSH access is configured and Python is installed, then run:

```bash
ansible-playbook setup.yml --limit debian
```

## Host Groups

Hosts can be added to groups to control which tools are installed:

| Group | Description |
|-------|-------------|
| `macs` | macOS machines |
| `debian` | Debian/Ubuntu machines |
| `with_login_tools` | CLI tools (aws, gcloud, gh, doctl, claude-code) |
| `with_gui_tools` | GUI applications (1password, iterm2, dbeaver) |
| `with_browsers` | Web browsers |
| `with_ai_tools` | AI tools (claude-code) |

## Infrastructure

The `infrastructure/` directory contains Pulumi code for provisioning cloud infrastructure:

```bash
cd infrastructure
npm install
pulumi up
```

This provisions a DigitalOcean Debian droplet that can be configured with the Ansible playbooks.

## Tools

### Shell & Terminal
- [zsh](tools/zsh/) - Z shell with plugins and configuration
- [tmux](tools/tmux/) - Terminal multiplexer
- [mosh](tools/mosh/) - Mobile shell for roaming connections
- [ssh](tools/ssh/) - Secure Shell configuration
- [iterm2](tools/iterm2/) - macOS terminal emulator

### Programming Languages
- [node](tools/node/) - JavaScript runtime via nvm
- [python](tools/python/) - Python via pyenv
- [rust](tools/rust/) - Rust via rustup
- [go](tools/go/) - Go programming language

### Editors
- [neovim](tools/neovim/) - Vim-based text editor

### CLI Utilities
- [fd](tools/fd/) - Fast file finder
- [fzf](tools/fzf/) - Fuzzy finder
- [ripgrep](tools/ripgrep/) - Fast grep alternative
- [bat](tools/bat/) - cat with syntax highlighting
- [eza](tools/eza/) - Modern ls replacement
- [jq](tools/jq/) - JSON processor
- [sd](tools/sd/) - sed alternative
- [tree](tools/tree/) - Directory tree viewer
- [wget](tools/wget/) - File downloader
- [lazygit](tools/lazygit/) - Terminal UI for git

### Cloud & DevOps
- [awscli](tools/awscli/) - AWS CLI
- [gcloud](tools/gcloud/) - Google Cloud CLI
- [doctl](tools/doctl/) - DigitalOcean CLI
- [gh](tools/gh/) - GitHub CLI
- [pulumi](tools/pulumi/) - Infrastructure as Code
- [1password_cli](tools/1password_cli/) - 1Password CLI

### Media
- [ffmpeg](tools/ffmpeg/) - Video/audio processing
- [imagemagick](tools/imagemagick/) - Image manipulation
- [yt-dlp](tools/yt-dlp/) - Video downloader
- [pandoc](tools/pandoc/) - Document converter
- [asciiquarium](tools/asciiquarium/) - ASCII art aquarium

### Security & Privacy
- [wireguard](tools/wireguard/) - VPN
- [tor](tools/tor/) - Tor Browser
- [mullvad](tools/mullvad/) - Mullvad VPN
- [1password](tools/1password/) - Password manager

### Browsers
- [chrome](tools/chrome/), [chromium](tools/chromium/), [chrome_canary](tools/chrome_canary/)
- [firefox](tools/firefox/), [firefox_developer](tools/firefox_developer/)
- [brave](tools/brave/), [arc](tools/arc/), [edge](tools/edge/)
- [opera](tools/opera/), [vivaldi](tools/vivaldi/)
- [librewolf](tools/librewolf/), [waterfox](tools/waterfox/), [zen](tools/zen/), [orion](tools/orion/), [min](tools/min/)

### Database
- [dbeaver](tools/dbeaver/) - Universal database tool

### AI
- [claude-code](tools/claude-code/) - Claude CLI assistant

## Project Structure

```
dotphiles/
├── bootstrap.sh          # macOS initial setup script
├── setup.yml             # Main playbook (imports all tool playbooks)
├── ansible.cfg           # Ansible configuration
├── localhost.yml         # Inventory for local machine
├── inventory.yml         # Inventory for remote machines
├── install_homebrew.yml  # Homebrew installation
├── install_ansible.yml   # Ansible installation
├── install_essentials.yml # Essential packages for Debian
├── infrastructure/       # Pulumi IaC for cloud provisioning
└── tools/                # Individual tool configurations
    └── <tool>/
        ├── install_<tool>.yml  # Ansible playbook
        └── README.md           # Tool documentation
```

## Adding a New Tool

1. Create a directory in `tools/`:
   ```bash
   mkdir tools/mytool
   ```

2. Create the install playbook `tools/mytool/install_mytool.yml`:
   ```yaml
   ---
   - name: Install mytool
     hosts: all
     gather_facts: true

     tasks:
       - name: Install mytool via Homebrew
         shell: /opt/homebrew/bin/brew install mytool
         args:
           creates: /opt/homebrew/bin/mytool
         when: ansible_os_family == "Darwin"

       - name: Install mytool via apt
         apt:
           name: mytool
           state: present
         become: yes
         when: ansible_os_family == "Debian"
   ```

3. Create `tools/mytool/README.md`:
   ```markdown
   # mytool

   Brief description of what the tool does.

   https://mytool.example.com/
   ```

4. Import the playbook in `setup.yml`:
   ```yaml
   - import_playbook: tools/mytool/install_mytool.yml
   ```
