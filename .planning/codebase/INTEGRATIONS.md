# External Integrations

**Analysis Date:** 2026-01-19

## Cloud Providers

**DigitalOcean:**
- Purpose: Primary cloud infrastructure
- IaC: Pulumi in `infrastructure/index.ts`
- CLI: doctl (v1.104.0)
- SDK: `@pulumi/digitalocean 4.56.0`
- Resources: Droplets (Debian 12, nyc1 region, s-2vcpu-4gb)
- Auth: `sshKeyFingerprint` via Pulumi config
- Install: `tools/doctl/install_doctl.yml`

**AWS:**
- Purpose: Available for cloud services
- CLI: awscli (v2, official installer)
- Auth: AWS credentials (configured separately)
- Install: `tools/awscli/install_awscli.yml`

**Google Cloud:**
- Purpose: Available for cloud services
- CLI: gcloud (google-cloud-cli)
- Auth: gcloud auth (configured separately)
- Install: `tools/gcloud/install_gcloud.yml`

## Secret Management

**1Password:**
- Purpose: Secrets retrieval during bootstrap and deployment
- CLI: op (`1password-cli`)
- Auth: Service account token at `~/.config/op/service-account-token`
- Usage: Fetch SSH keys, Age encryption keys
- References in playbooks:
  - `op://Automation/Age Key/Private Key`
  - `op://Automation/Age Key/Public Key`
  - `{{ op_ssh_private_key_ref }}` - SSH private key reference
- Install: `tools/1password_cli/install_1password_cli.yml`

**SOPS + Age:**
- Purpose: Encrypted secrets in git
- Config: `.sops.yaml` - Defines encryption rules
- Encrypted vars: `group_vars/all/personal-info.sops.yml`
- Key location: `~/.config/sops/age/keys.txt`
- Public key: `age13vqkx5d70vqhdvlnkm3y5htprafj0x0g6nngcqvn65at2lhs73hs3pgsgl`
- Ansible collection: `community.sops`
- Install: `tools/sops/install_sops.yml`, `tools/age/install_age.yml`

**Encrypted Variables:**
- `git_user_name` - Git commit name
- `git_user_email` - Git commit email
- `git_signing_key` - GPG/SSH signing key
- `ssh_public_key` - SSH public key for authorized_keys
- `ssh_default_user` - Default SSH username
- `github_username` - GitHub username
- `op_ssh_private_key_ref` - 1Password reference for SSH key

## Version Control

**GitHub:**
- Purpose: Repository hosting, CI/CD
- CLI: gh (`github-cli`)
- Auth: `gh auth login` (configured separately)
- Dotfiles repo: `github.com/matttelliott/_dotfiles`
- Install: `tools/gh/install_gh.yml`

**Git:**
- Signing: GPG/SSH key from encrypted vars
- Config templates:
  - `tools/git/gitconfig.darwin.j2` - macOS with login tools
  - `tools/git/gitconfig.debian.j2` - Linux with login tools
  - `tools/git/gitconfig.minimal.j2` - Minimal config
- Install: `tools/git/install_git.yml`

## Container Runtime

**Docker:**
- macOS: Colima + docker CLI (no Docker Desktop)
- Linux: docker-ce (Docker Community Edition)
- Compose: docker-compose / docker-compose-plugin
- Service: systemd on Linux
- Install: `tools/docker/install_docker.yml`

**Kubernetes:**
- kubectl - Kubernetes CLI
- k9s - Terminal UI for Kubernetes
- helm - Kubernetes package manager
- kubectx - Context/namespace switcher
- Install: `tools/kubectl/install_kubectl.yml`, etc.

## AI Services

**Claude Code:**
- Purpose: AI coding assistant
- Package: `@anthropic-ai/claude-code@latest` (npm)
- MCP Servers:
  - `@modelcontextprotocol/server-sequential-thinking@latest`
  - `@playwright/mcp@latest`
- Extensions: get-shit-done-cc (GSD workflow)
- Auth: Anthropic API key (configured separately)
- Install: `tools/claude-code/install_claude-code.yml`

**Neovim AI (nvim-ai):**
- Purpose: AI integration in Neovim
- Install: `tools/nvim-ai/install_nvim-ai.yml`

## Network Storage

**NAS:**
- Protocol: SMB/CIFS via autofs
- Server: `nas.home.lan`
- Shares: `home` mounted at `~/NAS/home`
- Auth: Guest (no password)
- Platforms: macOS (autofs), Debian (autofs), Arch (autofs)
- Install: `tools/nas/install_nas.yml`

## Network Security

**WireGuard:**
- Purpose: VPN
- CLI: wireguard-tools (wg)
- GUI: Available on GUI hosts
- Install: `tools/wireguard/install_wireguard.yml`

**fail2ban:**
- Purpose: Intrusion prevention
- Config: `tools/fail2ban/jail.local`
- Service: systemd on Linux
- Install: `tools/fail2ban/install_fail2ban.yml`

**Mullvad:**
- Purpose: Commercial VPN service
- Install: `tools/mullvad/install_mullvad.yml`

## SSH

**OpenSSH:**
- Server: openssh-server (Debian), openssh (Arch)
- Service: ssh (Debian), sshd (Arch)
- Config template: `tools/ssh/config.j2`
- Known hosts: macbookair, macmini, desktop, miniserver (all `.home.lan`)
- Key management: Fetched from 1Password
- Install: `tools/ssh/install_ssh.yml`

## Host Groups

Defined in `inventory.yml`:

| Group | Hosts | Purpose |
|-------|-------|---------|
| `macs` | macbookair, macmini | macOS machines |
| `debian` | miniserver | Debian servers |
| `arch` | desktop | Arch workstations |
| `with_login_tools` | all 4 | Git signing, SSH, cloud CLIs |
| `with_gui_tools` | macbookair, desktop, macmini | GUI applications |
| `with_browsers` | macbookair, desktop, macmini | Browser suite |
| `with_ai_tools` | macbookair, desktop, macmini | Claude Code, nvim-ai |
| `with_nas` | macbookair, desktop, macmini | NAS automount |

## Environment Configuration

**Required for bootstrap:**
- 1Password service account token (or manual secret entry)
- Age private key (or generate new)
- Network access to GitHub

**Required env vars (post-bootstrap):**
- `OP_SERVICE_ACCOUNT_TOKEN` - 1Password (read from file)
- Various cloud CLIs require their own auth (configured separately)

**Secrets location:**
- 1Password token: `~/.config/op/service-account-token`
- Age key: `~/.config/sops/age/keys.txt`
- SSH key: `~/.ssh/id_rsa` (deployed from 1Password)

## Webhooks & Callbacks

**Incoming:** None (dotfiles repo, no CI)

**Outgoing:** None

## Local Network

**Hosts:**
- macbookair.home.lan
- macmini.home.lan
- desktop.home.lan
- miniserver.home.lan
- nas.home.lan

**Services:**
- SSH on all hosts
- NAS (SMB) on nas.home.lan

---

*Integration audit: 2026-01-19*
