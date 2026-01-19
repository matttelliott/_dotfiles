# External Integrations

**Analysis Date:** 2026-01-19

## APIs & External Services

**GitHub:**
- GitHub CLI (`gh`) for repository operations
- SSH key-based authentication
- Dotfiles cloned from `github.com/matttelliott/_dotfiles`
- Config: `tools/gh/install_gh.yml`

**1Password:**
- 1Password CLI (`op`) for secrets management
- Service account token authentication
- Retrieves SSH private keys, Age keys
- Token location: `~/.config/op/service-account-token`
- Config: `tools/1password_cli/install_1password_cli.yml`

**Anthropic (Claude):**
- Claude Code CLI (`@anthropic-ai/claude-code`)
- Claude Desktop application
- MCP servers: Sequential Thinking, Playwright
- Get Shit Done (GSD) workflow tools
- Config: `tools/claude-code/install_claude-code.yml`

**OpenAI:**
- ChatGPT Desktop application
- OpenAI Codex CLI
- Config: `tools/chatgpt-desktop/install_chatgpt-desktop.yml`, `tools/codex/install_codex.yml`

## Cloud Providers

**DigitalOcean:**
- Managed via Pulumi IaC (`infrastructure/index.ts`)
- doctl CLI for manual operations
- Droplet provisioning (Debian 12, nyc1, s-2vcpu-4gb)
- SSH key authentication via fingerprint
- Config: `tools/doctl/install_doctl.yml`

**AWS:**
- AWS CLI v2 installed
- No active IaC management
- Config: `tools/awscli/install_awscli.yml`

**Google Cloud:**
- gcloud CLI installed
- No active IaC management
- Config: `tools/gcloud/install_gcloud.yml`

## Data Storage

**Databases:**
- DBeaver GUI client installed
- No managed database infrastructure
- Config: `tools/dbeaver/install_dbeaver.yml`

**File Storage:**
- NAS automount via SMB/CIFS
- Server: `nas.home.lan`
- Shares: `home` mounted to `~/NAS/home`
- Credentials: `~/.nas-credentials` (guest access)
- Config: `tools/nas/install_nas.yml`

**Caching:**
- None (local development only)

## Secrets Management

**SOPS + Age:**
- Age encryption for SOPS files
- Age key location: `~/.config/sops/age/keys.txt`
- Encrypted file: `group_vars/all/personal-info.sops.yml`
- Ansible collection: `community.sops`
- Config: `ansible.cfg`, `tools/sops/install_sops.yml`, `tools/age/install_age.yml`

**1Password Integration:**
- Service account for automation
- SSH private key retrieval: `op://Automation/SSH Key/private key`
- Age key retrieval: `op://Automation/Age Key/Private Key`
- Bootstrap flow handles token setup

**Encrypted Variables:**
```yaml
# group_vars/all/personal-info.sops.yml
git_user_name: [encrypted]
git_user_email: [encrypted]
git_signing_key: [encrypted]
ssh_public_key: [encrypted]
github_username: [encrypted]
op_ssh_private_key_ref: [encrypted]
```

## Authentication & Identity

**SSH:**
- Key-based authentication to all hosts
- Public key deployed to `~/.ssh/authorized_keys`
- Private key fetched from 1Password
- Config: `tools/ssh/install_ssh.yml`

**Git Signing:**
- SSH key signing enabled
- Signing key from encrypted vars
- Templates: `tools/git/gitconfig.darwin.j2`, `tools/git/gitconfig.debian.j2`

## Networking

**WireGuard VPN:**
- wireguard-tools installed
- Config: `tools/wireguard/install_wireguard.yml`

**Mullvad VPN:**
- GUI client available
- Config: `tools/mullvad/install_mullvad.yml`

**fail2ban:**
- SSH brute-force protection on Linux hosts
- Config: `tools/fail2ban/install_fail2ban.yml`

## Monitoring & Observability

**Error Tracking:**
- None (local development focus)

**Logs:**
- System default logging
- fail2ban for security events

## CI/CD & Deployment

**Hosting:**
- DigitalOcean Droplets (managed via Pulumi)
- Self-hosted infrastructure on home network

**CI Pipeline:**
- None (manual ansible-playbook execution)
- Bootstrap via curl: `curl -fsSL https://raw.githubusercontent.com/matttelliott/_dotfiles/master/bootstrap.sh | bash`

**Deployment Flow:**
1. Bootstrap installs Ansible dependencies
2. User selects host groups (login_tools, gui_tools, browsers, ai_tools)
3. `ansible-playbook setup.yml` runs all tool playbooks
4. Remote hosts: `./setup-all.sh` or `ansible-playbook setup.yml --limit <host>`

## Environment Configuration

**Required env vars:**
- None required at runtime (all in files)

**Critical paths:**
- `~/.config/sops/age/keys.txt` - Age decryption key
- `~/.config/op/service-account-token` - 1Password automation
- `~/.ssh/id_rsa` - SSH private key
- `~/.nvm/` - Node.js version manager

**Secrets location:**
- 1Password vault: "Automation"
- Local encrypted: `group_vars/all/personal-info.sops.yml`

## Container & Orchestration

**Docker:**
- macOS: Colima + docker CLI (no Docker Desktop)
- Linux: docker-ce from official repos
- Config: `tools/docker/install_docker.yml`

**Kubernetes:**
- kubectl CLI
- k9s TUI dashboard
- Helm package manager
- kubectx context switcher
- No managed clusters (CLI tools only)

## Webhooks & Callbacks

**Incoming:**
- None

**Outgoing:**
- None

## Home Network Hosts

**Managed hosts (inventory.yml):**
| Host | OS | IP | Groups |
|------|----|----|--------|
| macbookair | macOS | macbookair.home.lan | macs, with_login_tools, with_gui_tools, with_browsers, with_ai_tools, with_nas |
| macmini | macOS | macmini.home.lan | macs, with_login_tools, with_gui_tools, with_browsers, with_ai_tools, with_nas |
| desktop | Arch | desktop.home.lan | arch, with_login_tools, with_gui_tools, with_browsers, with_ai_tools, with_nas |
| miniserver | Debian | miniserver.home.lan | debian, with_login_tools |

---

*Integration audit: 2026-01-19*
