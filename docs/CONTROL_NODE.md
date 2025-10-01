# Ansible Control Node Setup

This machine is configured as an Ansible control node for deploying dotfiles to remote hosts.

## Control Node Information

- **Location**: `/home/developer/dotfiles-ansible`
- **Ansible Version**: Installed via apt
- **Python**: `/usr/bin/python3`
- **SSH Key**: `~/.ssh/ansible_control` (ed25519)

## Directory Structure

```
dotfiles-ansible/
├── ansible.cfg           # Ansible configuration
├── site.yml             # Local installation playbook
├── deploy.yml           # Remote deployment playbook
├── inventory/
│   ├── hosts.yml       # Inventory of remote hosts
│   ├── group_vars/     # Group-specific variables
│   └── host_vars/      # Host-specific variables
├── roles/
│   ├── base-packages/  # System packages
│   ├── zsh/            # Zsh configuration
│   ├── tmux/           # Tmux configuration
│   └── neovim/         # Neovim configuration
├── scripts/
│   └── install.sh      # Bootstrap script
└── docs/
    └── CONTROL_NODE.md # This file
```

## SSH Key Management

### Control Node SSH Key

An SSH key has been generated for Ansible deployments:

```bash
# Public key (share this with remote hosts)
cat ~/.ssh/ansible_control.pub

# Add to remote host's authorized_keys
ssh-copy-id -i ~/.ssh/ansible_control.pub user@remote-host
```

### Manual Key Distribution

```bash
# Copy public key to remote host
scp ~/.ssh/ansible_control.pub user@remote-host:~/

# On remote host, add to authorized_keys
ssh user@remote-host
mkdir -p ~/.ssh
chmod 700 ~/.ssh
cat ~/ansible_control.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
rm ~/ansible_control.pub
```

## Adding Remote Hosts

Edit `inventory/hosts.yml` and uncomment/add your hosts:

```yaml
dev_servers:
  hosts:
    dev1.example.com:
      ansible_host: 192.168.1.10
      ansible_user: developer
      ansible_ssh_private_key_file: ~/.ssh/ansible_control
```

## Deployment Commands

### Test Connectivity

```bash
# Ping all hosts
ansible all -m ping

# Ping specific group
ansible dev_servers -m ping

# Ping specific host
ansible dev1.example.com -m ping
```

### Deploy Dotfiles to Remote Hosts

```bash
# Deploy to all remote hosts (excludes localhost)
ansible-playbook deploy.yml --ask-become-pass

# Deploy to specific group
ansible-playbook deploy.yml --limit dev_servers --ask-become-pass

# Deploy to specific host
ansible-playbook deploy.yml --limit dev1.example.com --ask-become-pass

# Deploy only specific components
ansible-playbook deploy.yml --tags zsh,tmux --ask-become-pass

# Dry run (check mode)
ansible-playbook deploy.yml --check --ask-become-pass
```

### Ad-hoc Commands

```bash
# Check disk space on all hosts
ansible all -m shell -a "df -h"

# Check zsh version on all hosts
ansible all -m shell -a "zsh --version"

# Update packages on Debian hosts
ansible all -b -m apt -a "update_cache=yes" --limit debian

# Gather facts from all hosts
ansible all -m setup
```

## Local Installation

To reinstall dotfiles on this machine:

```bash
ansible-playbook site.yml --ask-become-pass
```

## Inventory Management

### Group Variables

Create group-specific variables:

```bash
# For all dev servers
vim inventory/group_vars/dev_servers.yml
```

```yaml
---
# Dev servers use different shell theme
zsh_theme: "robbyrussell"
```

### Host Variables

Create host-specific variables:

```bash
# For specific host
vim inventory/host_vars/dev1.example.com.yml
```

```yaml
---
# This host needs custom tmux prefix
tmux_prefix: "C-b"
```

## SSH Configuration

Add to `~/.ssh/config` for easier access:

```
Host dev1
    HostName 192.168.1.10
    User developer
    IdentityFile ~/.ssh/ansible_control
    ForwardAgent yes

Host prod*
    User deploy
    IdentityFile ~/.ssh/ansible_control
    StrictHostKeyChecking yes
```

## Security Best Practices

1. **Never commit private SSH keys** - They're in `.gitignore`
2. **Use SSH key authentication** - Avoid password-based auth
3. **Limit SSH key permissions** - `chmod 600 ~/.ssh/ansible_control`
4. **Use Ansible Vault** for sensitive variables:
   ```bash
   ansible-vault create inventory/group_vars/prod_servers/vault.yml
   ansible-playbook deploy.yml --ask-vault-pass
   ```
5. **Keep control node secure** - Regular updates, firewall, etc.

## Troubleshooting

### SSH Connection Issues

```bash
# Test SSH manually
ssh -i ~/.ssh/ansible_control user@remote-host

# Verbose Ansible connection test
ansible dev1.example.com -m ping -vvv

# Check SSH agent
eval $(ssh-agent)
ssh-add ~/.ssh/ansible_control
```

### Permission Issues

```bash
# Ensure remote user has sudo access
ansible all -b -m shell -a "whoami"

# Test with password prompt
ansible-playbook deploy.yml --ask-become-pass
```

### Inventory Issues

```bash
# List all hosts
ansible-inventory --list

# Show specific host variables
ansible-inventory --host dev1.example.com

# Validate inventory syntax
ansible-inventory --syntax-check
```

## Updating the Control Node

```bash
# Update Ansible
sudo apt update && sudo apt upgrade ansible

# Update dotfiles repository
git pull

# Test changes locally first
ansible-playbook site.yml --check
```

## Example: Deploy to New Host

```bash
# 1. Add host to inventory
vim inventory/hosts.yml

# 2. Copy SSH key to host
ssh-copy-id -i ~/.ssh/ansible_control.pub user@new-host

# 3. Test connectivity
ansible new-host -m ping

# 4. Deploy dotfiles
ansible-playbook deploy.yml --limit new-host --ask-become-pass

# 5. SSH into host and verify
ssh user@new-host
exec zsh
```

## Maintenance

### Regular Tasks

- **Update inventory** when adding/removing hosts
- **Test deployments** in dev before prod
- **Keep roles updated** with latest configurations
- **Document customizations** in this file
- **Backup** `~/.ssh/ansible_control` securely

### Version Control

```bash
# Initial commit
git add .
git commit -m "Initial dotfiles-ansible control node setup"

# Create remote repository (GitHub/GitLab)
git remote add origin git@github.com:username/dotfiles-ansible.git
git push -u origin master

# Regular updates
git add .
git commit -m "Update: <description>"
git push
```

---

**Control Node Ready!** 🚀

This machine can now deploy dotfiles to remote hosts using Ansible.
