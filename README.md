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

## Secrets Management

This repo uses **SOPS + Age** for encrypting sensitive data and **1Password CLI** for distributing secrets to machines.

### How It Works

1. Personal info (git email, SSH keys, etc.) is encrypted in `group_vars/all/personal-info.sops.yml`
2. The Age private key decrypts the SOPS file during Ansible runs
3. Both the Age key and SSH private key are stored in 1Password
4. A 1Password service account token is the only secret you need to provide

### Bootstrap Setup

During `bootstrap.sh`, you'll be prompted for a **1Password service account token**. This token:
- Fetches the Age key (for SOPS decryption)
- Fetches SSH keys (for git signing and remote access)

**Create a service account:**
1. Go to [1password.com](https://1password.com) → Developer → Service Accounts
2. Create a new service account
3. Grant access to a vault containing:
   - **Age Key** item with `Private Key` and `Public Key` fields
   - **SSH Key** item with `Private Key` field

### 1Password Vault Structure

```
Automation (vault)
├── Age Key
│   ├── Private Key: AGE-SECRET-KEY-...
│   └── Public Key: age1...
└── SSH Key
    └── Private Key: -----BEGIN OPENSSH PRIVATE KEY-----...
```

### Setting Up a New Machine

**Option 1: With 1Password (recommended)**
```bash
# Bootstrap will prompt for service account token
curl -fsSL https://raw.githubusercontent.com/matttelliott/_dotfiles/master/bootstrap.sh | bash
```

**Option 2: Manual setup**
```bash
# Provide Age key manually during bootstrap
mkdir -p ~/.config/sops/age
echo "AGE-SECRET-KEY-..." > ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt

# Then run bootstrap (skip 1Password prompt)
curl -fsSL https://raw.githubusercontent.com/matttelliott/_dotfiles/master/bootstrap.sh | bash
```

### Remote Machine Setup with 1Password

For remote machines to fetch SSH keys via 1Password CLI:

```bash
# Copy service account token to remote machine
ssh myserver "mkdir -p ~/.config/op && chmod 700 ~/.config/op"
scp ~/.config/op/service-account-token myserver:~/.config/op/

# Run playbook - SSH key will be fetched automatically
ansible-playbook setup.yml --limit myserver
```

### Encrypting Personal Info

To update encrypted values:

```bash
# Edit encrypted file (decrypts in editor, re-encrypts on save)
SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops group_vars/all/personal-info.sops.yml
```

### For New Users Cloning This Repo

If you're forking this repo for your own use:

1. Generate a new Age key:
   ```bash
   age-keygen -o ~/.config/sops/age/keys.txt
   ```

2. Update `.sops.yaml` with your public key:
   ```yaml
   creation_rules:
     - path_regex: group_vars/.*\.sops\.yml$
       age: age1your-public-key-here
   ```

3. Create your own `personal-info.sops.yml`:
   ```bash
   cp group_vars/all/defaults.yml group_vars/all/personal-info.yml
   # Edit with your values
   sops -e -i group_vars/all/personal-info.yml
   mv group_vars/all/personal-info.yml group_vars/all/personal-info.sops.yml
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
| `with_ai_tools` | Claude Code, nvim-ai |
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
- **nvim-ai** - Separate neovim instance for AI-assisted coding:
  - Inherits full base neovim config
  - Adds AI plugins (Claude Code integrations, etc.)
  - Isolated data/state via `NVIM_APPNAME`
  - Launch with `nvim-ai` command

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

## Themes

Use the `themesetting` command to interactively switch colors, fonts, and styles:

```bash
themesetting
```

This uses fzf to select from available themes in the `themes/` directory:

| Type | Files | Description |
|------|-------|-------------|
| color | `colors_*.yml` | Color schemes (tokyonight, gruvbox, dracula, etc.) |
| font | `font_*.yml` | Terminal fonts (jetbrainsmono, firacode, etc.) |
| style | `style_*.yml` | Powerline separator styles (angle, round) |

### Theme Files

Theme playbooks modify config files for tmux, starship, neovim, wezterm, lazygit, fzf, and bat.

## Nerd Font / Powerline Characters

The tmux statusline, neovim statusline, and starship prompt use special glyphs from Nerd Fonts (Unicode Private Use Area). These characters require a patched font to display correctly.

**Key files with special characters:**
- `tools/tmux/tmux.conf.j2` - Powerline arrows, icons
- `tools/starship/starship.toml` - Powerline arrows, icons
- `tools/neovim/nvim/init.lua` - Statusline arrows, diagnostic icons

### Powerline Separator Glyphs

| Style | Right | Left | Code Points |
|-------|-------|------|-------------|
| Angled | `` | `` | U+E0B0, U+E0B2 |
| Round | `` | `` | U+E0B4, U+E0B6 |

### Editing Special Characters

These Unicode Private Use Area characters display inconsistently in editors and are problematic for LLMs. When editing files containing these glyphs:

**For Ansible playbooks** - Use `\uXXXX` escape sequences in variables:
```yaml
vars:
  arrow_right: "\uE0B0"
  round_right: "\uE0B4"
tasks:
  - name: Replace separator
    ansible.builtin.replace:
      path: ~/.tmux.conf
      regexp: "{{ arrow_right }}"
      replace: "{{ round_right }}"
```

**For Lua (neovim)** - Use `vim.fn.nr2char()`:
```lua
local arrow_right = vim.fn.nr2char(0xe0b0)
local round_right = vim.fn.nr2char(0xe0b4)
```

**For Python** - Use `chr()`:
```python
arrow_right = chr(0xE0B0)
round_right = chr(0xE0B4)
```

See `themes/style_angle.yml` and `themes/style_round.yml` for complete examples.

## Security Considerations

### Curl-to-Shell Installation Patterns

Some tools use `curl | bash` installation patterns (downloading and executing remote scripts). This is a known supply chain security risk but sometimes unavoidable when package managers don't provide the tool or the official installation method requires it.

**Mitigation strategies applied in this repo:**
- **Pinned versions:** Scripts locked to specific versions/commits to prevent silent updates
- **Documented risks:** Unpinnable scripts have security comments in playbooks
- **HTTPS only:** All curl commands require HTTPS
- **Checksum verification:** Binary downloads use SHA256 checksums (see Phase 9)

**Affected tools:**

| Tool | Status | Mitigation | File |
|------|--------|------------|------|
| nvm | Pinned to v0.40.1 | Version in URL | `tools/node/install_node.yml` |
| Homebrew | Pinned to commit SHA | Git commit `90fa3d58...` | `bootstrap.sh`, `tools/homebrew/install_homebrew.yml` |
| Pulumi | Pinned to v3.216.0 | `--version` flag | `tools/pulumi/install_pulumi.yml` |
| uv | Pinned to v0.9.26 | Version in URL | `tools/python/install_python.yml` |
| rustup | Cannot pin | HTTPS + official domain | `tools/rust/install_rust.yml` |
| starship | Cannot pin | HTTPS + official domain | `tools/starship/install_starship.yml` |

### Updating Pinned Versions

To update a pinned curl-to-shell script:

1. **Check for latest release:**
   ```bash
   # For GitHub repos (nvm, Homebrew)
   curl -s https://api.github.com/repos/<org>/<repo>/releases/latest | jq -r .tag_name

   # For Homebrew (uses commits, not releases)
   # Visit: https://github.com/Homebrew/install/commits/master
   ```

2. **Review changelog** for security fixes or breaking changes

3. **Update version** in the corresponding playbook file

4. **Test with check mode:**
   ```bash
   ansible-playbook tools/<tool>/install_<tool>.yml --check --diff
   ```

5. **Test on clean system** or VM if possible

### Unpinnable Tools

Some installers have no versioning mechanism:

- **rustup:** The official installer at `https://sh.rustup.rs` has no version parameter.
  - Alternative: [Standalone installers with GPG signatures](https://forge.rust-lang.org/infra/other-installation-methods.html)
  - Current mitigation: HTTPS-only, official domain, documented risk in playbook

- **starship:** The installer at `https://starship.rs/install.sh` has no version parameter.
  - Alternative: Download binary directly from [GitHub releases](https://github.com/starship/starship/releases) with SHA256 verification
  - Current mitigation: HTTPS-only, official domain

## Troubleshooting

### Theme Changes

#### Powerline Separators Show as Boxes

**Cause:** Terminal doesn't have a Nerd Font installed or configured.

**Fix:**
1. The playbook installs JetBrainsMono Nerd Font automatically
2. Set your terminal font to "JetBrainsMono Nerd Font" (or another Nerd Font)
3. Restart your terminal

#### Colors Unreadable After Theme Change

**Cause:** Theme colors don't match your terminal background or personal preference.

**Fix:**
1. Restore defaults: `ansible-playbook themes/apply_defaults.yml`
2. Try a different theme interactively: `themesetting`

#### Theme Playbook Corrupted Special Characters

**Cause:** Nerd Font glyphs were edited directly instead of using escape sequences (common when LLMs or editors modify these files).

**Fix:**
1. Restore from git: `git checkout -- themes/_style.yml themes/_color.yml`
2. Review CLAUDE.md "Nerd Font / Powerline Characters" section
3. Use escape sequences for any edits (`\uE0B0` not the literal character)

### Playbook Failures

#### Playbook Stopped with Error

**Recovery:** Ansible playbooks are idempotent - safe to rerun.

1. Read the error message - usually indicates missing dependency or network issue
2. Rerun the playbook: `ansible-playbook setup.yml`
3. If a single tool fails, run just that tool: `ansible-playbook tools/<tool>/install_<tool>.yml`

**Common causes:**
- Network timeout - rerun playbook
- Missing dependency - install manually first, then rerun
- Permission denied - check `become: yes` in task (required for apt/pacman)

#### GPG Key Expired (APT Update Fails)

**Symptoms:**
```
Err:1 https://cli.github.com/packages stable InRelease
  The following signatures were invalid: EXPKEYSIG ...
```

**Recovery:**
1. Check the playbook for key fingerprint comment (e.g., `tools/gh/install_gh.yml`)
2. Re-download the key: `curl -fsSL <KEY_URL> | sudo gpg --dearmor -o /etc/apt/keyrings/<tool>.gpg`
3. Rerun apt update: `sudo apt update`

**Known expirations:**
- GitHub CLI key expires September 2026 (check [GitHub changelog](https://github.blog/changelog) for key rotation announcements)

#### SOPS Decryption Failed

**Symptoms:**
```
Failed to get the data key required to decrypt the SOPS file.
```

**Recovery:**
1. Check Age key exists: `ls ~/.config/sops/age/keys.txt`
2. If missing, restore from 1Password:
   ```bash
   op read "op://Automation/Age Key/Private Key" > ~/.config/sops/age/keys.txt
   chmod 600 ~/.config/sops/age/keys.txt
   ```
3. Rerun the playbook

### Starting Over

If everything is broken and you want a clean slate:

```bash
# Backup your customizations
cp ~/.zshrc ~/.zshrc.backup
cp ~/.tmux.conf ~/.tmux.conf.backup

# Remove dotfiles
cd ~
rm -rf _dotfiles

# Re-bootstrap
curl -fsSL https://raw.githubusercontent.com/matttelliott/_dotfiles/master/bootstrap.sh | bash
```

**Note:** Ansible playbooks are idempotent - they will not break existing working setups. Most "failures" are recoverable by simply rerunning the playbook. The nuclear option above is rarely needed.

## Project Structure

```
_dotfiles/
├── bootstrap.sh          # Interactive bootstrap script
├── setup.yml             # Main playbook
├── ansible.cfg           # Ansible config (SOPS plugin)
├── .sops.yaml            # SOPS encryption config
├── requirements.yml      # Ansible Galaxy dependencies
├── localhost.yml         # Local machine inventory (generated)
├── inventory.yml         # Remote machines inventory
├── group_vars/
│   └── all/
│       ├── defaults.yml              # Default values for new users
│       └── personal-info.sops.yml    # Encrypted personal data
├── infrastructure/       # Pulumi IaC
├── themes/               # Color, font, and style themes
└── tools/
    ├── arch/             # Arch-specific setup
    ├── debian/           # Debian-specific setup
    ├── macos/            # macOS-specific setup
    ├── yay/              # AUR helper for Arch
    └── <tool>/
        ├── install_<tool>.yml
        └── <tool>.zsh    # Shell config (optional)
```
