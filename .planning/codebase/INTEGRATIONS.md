# External Integrations

**Analysis Date:** 2026-01-18

## APIs & External Services

**Cloud Providers:**

- DigitalOcean - Infrastructure hosting (Droplets)
  - SDK/Client: `@pulumi/digitalocean` 4.56.0 (`infrastructure/package.json`)
  - CLI: doctl (`tools/doctl/install_doctl.yml`)
  - Auth: `doctl auth init` (manual after install)

- Google Cloud Platform
  - CLI: google-cloud-sdk (`tools/gcloud/install_gcloud.yml`)
  - Auth: `gcloud auth login` (manual after install)

- Amazon Web Services
  - CLI: awscli (`tools/awscli/install_awscli.yml`)
  - Auth: `~/.aws/credentials` (manual configuration)

**Version Control:**

- GitHub
  - CLI: gh (`tools/gh/install_gh.yml`)
  - Auth: `gh auth login` (manual after install)
  - Used for: dotfiles repo cloning, PR management

**AI Services:**

- Anthropic Claude
  - CLI: @anthropic-ai/claude-code (npm global) (`tools/claude-code/install_claude-code.yml`)
  - Config: `~/.claude/settings.json`, `~/.claude/CLAUDE.md`

## Data Storage

**Databases:**

- None configured directly
- DBeaver installed for database management (`tools/dbeaver/install_dbeaver.yml`)

**File Storage:**

- NAS via SMB/CIFS
  - Server: `nas.home.lan`
  - Shares: `home`
  - Mount: `~/NAS/home` via autofs (`tools/nas/install_nas.yml`)
  - Auth: Guest access (credentials at `~/.nas-credentials` on Linux)

**Caching:**

- None

## Authentication & Identity

**Auth Provider:**

- 1Password (via service account)
  - CLI: op (`tools/1password_cli/install_1password_cli.yml`)
  - Token: `~/.config/op/service-account-token`
  - Used for: SSH key retrieval, Age key retrieval

**SSH:**

- Key-based authentication (`tools/ssh/install_ssh.yml`)
- Private key: `~/.ssh/id_rsa` (fetched from 1Password via `op_ssh_private_key_ref`)
- Public key: Deployed via `ssh_public_key` variable
- Config: `~/.ssh/config` (templated from `tools/ssh/config.j2`)

**Secrets Management:**

- SOPS + Age
  - Config: `.sops.yaml` (Age public key)
  - Private key: `~/.config/sops/age/keys.txt`
  - Encrypted files: `group_vars/all/personal-info.sops.yml`
  - Ansible plugin: `community.sops.sops` (`ansible.cfg`)

## Monitoring & Observability

**Error Tracking:**

- None

**Logs:**

- Standard systemd journal (Linux services)
- Ansible task output during playbook runs

## CI/CD & Deployment

**Hosting:**

- DigitalOcean Droplet (`infrastructure/index.ts`)
  - Image: debian-12-x64
  - Region: nyc1
  - Size: s-2vcpu-4gb

**CI Pipeline:**

- None automated
- Manual: `ansible-playbook setup.yml --check --diff` for dry runs
- Lint: `ansible-lint setup.yml`, `ansible-lint tools/*/install_*.yml`

**Deployment Methods:**

- Bootstrap: `curl -fsSL .../bootstrap.sh | bash` (new machines)
- Local: `ansible-playbook setup.yml --connection=local --limit $(hostname -s)`
- Remote: `ansible-playbook setup.yml --limit <hostname>`
- All: `./setup-all.sh`

## Environment Configuration

**Required env vars:**

- None at runtime (Ansible uses inventory and group_vars)

**Required files:**

- `~/.config/op/service-account-token` - 1Password service account token (for secrets)
- `~/.config/sops/age/keys.txt` - Age private key (for SOPS decryption)

**Secrets location:**

- 1Password vault "Automation":
  - `op://Automation/Age Key/Private Key`
  - `op://Automation/Age Key/Public Key`
  - SSH private key (via `op_ssh_private_key_ref`)
- Local encrypted: `group_vars/all/personal-info.sops.yml`

## Webhooks & Callbacks

**Incoming:**

- None

**Outgoing:**

- None

## Network Services

**VPN:**

- WireGuard (`tools/wireguard/install_wireguard.yml`)
  - Tools installed, configuration manual
  - GUI available on with_gui_tools hosts (`tools/wireguard_gui/`)

**Remote Access:**

- SSH (port 22) - All hosts
- Mosh - Mobile shell for unreliable connections (`tools/mosh/install_mosh.yml`)

**Fail2ban:**

- Installed on Linux hosts (`tools/fail2ban/install_fail2ban.yml`)
- Default configuration for SSH protection

## Container Runtime

**Docker:**

- macOS: Colima + docker CLI (no Docker Desktop)
- Linux: docker-ce from official Docker repo
- Compose: docker-compose plugin
- Service: Enabled and started on Linux (`tools/docker/install_docker.yml`)

**Kubernetes:**

- kubectl - Cluster management (`tools/kubectl/install_kubectl.yml`)
- k9s - TUI for cluster management (`tools/k9s/install_k9s.yml`)
- helm - Package manager (`tools/helm/install_helm.yml`)
- kubectx/kubens - Context switching (`tools/kubectx/install_kubectx.yml`)

## Host Groups

Host group membership controls which integrations are installed:

| Group              | Integrations Enabled                                                             |
| ------------------ | -------------------------------------------------------------------------------- |
| `with_login_tools` | 1password_cli, doctl, gcloud, awscli, gh, kubectl, k9s, helm, kubectx, wireguard |
| `with_gui_tools`   | 1password (app), wireguard_gui, dbeaver, wezterm                                 |
| `with_ai_tools`    | claude-code, claude-desktop, chatgpt-desktop, codex                              |
| `with_nas`         | NAS automount via autofs                                                         |

---

_Integration audit: 2026-01-18_
