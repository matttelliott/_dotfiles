# Ansible Vault Guide

This repository uses Ansible Vault to securely store sensitive credentials like API tokens and passwords.

## Overview

**Ansible Vault** encrypts sensitive data at rest, allowing you to safely commit encrypted secrets to version control.

## Current Setup

### Vault Password File

Location: `~/.ansible_vault_pass`

This file contains the master password used to encrypt/decrypt vault files. It's automatically configured in `ansible.cfg`:

```ini
[defaults]
vault_password_file = ~/.ansible_vault_pass
```

⚠️ **IMPORTANT**: The vault password file is in `.gitignore` - **never commit it to version control**!

### Encrypted Secrets

**File**: `group_vars/all/vault.yml` (encrypted)

Currently stores:
- `digitalocean_api_token` - DigitalOcean API token for doctl

## Working with Vault

### View Encrypted File

```bash
ansible-vault view group_vars/all/vault.yml
```

### Edit Encrypted File

```bash
ansible-vault edit group_vars/all/vault.yml
```

This opens the file in your `$EDITOR` for editing. Changes are automatically re-encrypted when you save and exit.

### Encrypt a New File

```bash
# Create plaintext file
cat > secrets.yml << EOF
---
my_secret_key: supersecretvalue
EOF

# Encrypt it
ansible-vault encrypt secrets.yml
```

### Decrypt a File

```bash
# Decrypt to stdout
ansible-vault decrypt secrets.yml --output=-

# Decrypt and save
ansible-vault decrypt secrets.yml --output=secrets-plain.yml
```

### Re-key (Change Vault Password)

```bash
ansible-vault rekey group_vars/all/vault.yml
```

## Using Vault Variables in Playbooks

Vault variables are automatically decrypted when playbooks run:

```yaml
# In a playbook or role
- name: Configure service with API token
  template:
    src: config.yaml.j2
    dest: /etc/service/config.yaml
  vars:
    api_token: "{{ digitalocean_api_token }}"  # From vault.yml
```

## Best Practices

### 1. Separate Encrypted and Plaintext Variables

**Recommended Structure:**

```
group_vars/all/
├── vars.yml        # Plaintext variables
└── vault.yml       # Encrypted secrets (encrypted)
```

**vars.yml** (plaintext):
```yaml
---
api_endpoint: "https://api.digitalocean.com/v2"
api_timeout: 30
```

**vault.yml** (encrypted):
```yaml
---
digitalocean_api_token: "dop_v1_..."
```

### 2. Naming Convention

Prefix vault variables with `vault_`:

```yaml
# vault.yml
---
vault_digitalocean_api_token: "dop_v1_..."
vault_github_token: "ghp_..."
```

Then reference them in vars.yml:
```yaml
# vars.yml
---
digitalocean_api_token: "{{ vault_digitalocean_api_token }}"
github_token: "{{ vault_github_token }}"
```

This makes it clear which variables come from vault.

### 3. Multiple Vault Files

For different environments:

```
group_vars/
├── production/
│   ├── vars.yml
│   └── vault.yml       # Production secrets
└── development/
    ├── vars.yml
    └── vault.yml       # Development secrets
```

### 4. Vault Password Management

**Option 1**: File-based (current setup)
```bash
# ~/.ansible_vault_pass
ansible-vault-password-1759283122
```

**Option 2**: Prompt for password
```bash
ansible-playbook site.yml --ask-vault-pass
```

**Option 3**: Script-based (for automation)
```bash
# vault-pass.sh
#!/bin/bash
cat /path/to/secure/location/vault-password

# Make executable and use
chmod +x vault-pass.sh
ansible-playbook site.yml --vault-password-file=./vault-pass.sh
```

### 5. Vault IDs (Multiple Passwords)

For different vault files with different passwords:

```bash
# Encrypt with specific vault ID
ansible-vault encrypt --vault-id dev@prompt secrets-dev.yml
ansible-vault encrypt --vault-id prod@prompt secrets-prod.yml

# Use in playbook
ansible-playbook site.yml --vault-id dev@prompt --vault-id prod@prompt
```

## Adding New Secrets

### Step 1: Edit the Vault File

```bash
ansible-vault edit group_vars/all/vault.yml
```

### Step 2: Add Your Secret

```yaml
---
# Existing secrets
digitalocean_api_token: dop_v1_...

# Add new secret
github_token: ghp_1234567890abcdef
aws_access_key: AKIAIOSFODNN7EXAMPLE
```

### Step 3: Use in Playbook/Role

```yaml
- name: Configure GitHub CLI
  template:
    src: github-config.j2
    dest: ~/.config/gh/config.yml
  vars:
    gh_token: "{{ github_token }}"
```

## Security Checklist

- [ ] Vault password file (`~/.ansible_vault_pass`) is in `.gitignore`
- [ ] Vault password file has restrictive permissions (`chmod 600`)
- [ ] All sensitive data is in encrypted vault files
- [ ] Vault files are committed to git in encrypted form
- [ ] Plaintext secrets are never committed to git
- [ ] Vault password is stored securely (password manager, encrypted storage)
- [ ] Regular rotation of vault password
- [ ] Team members have their own vault password files (not shared)

## Troubleshooting

### "Decryption failed"

**Problem**: Wrong vault password

**Solution**:
```bash
# Check vault password file
cat ~/.ansible_vault_pass

# Try decrypting manually
ansible-vault view group_vars/all/vault.yml
```

### "vault password file not found"

**Problem**: Vault password file doesn't exist

**Solution**:
```bash
# Create vault password file
echo "your-vault-password" > ~/.ansible_vault_pass
chmod 600 ~/.ansible_vault_pass
```

### Variable not defined error

**Problem**: Vault file not loaded

**Solution**:
```bash
# Verify file location
ls -la group_vars/all/vault.yml

# Check if encrypted
head -1 group_vars/all/vault.yml  # Should show: $ANSIBLE_VAULT;1.1;AES256
```

## Example: Adding AWS Credentials

```bash
# 1. Edit vault file
ansible-vault edit group_vars/all/vault.yml

# 2. Add credentials
---
digitalocean_api_token: dop_v1_...
aws_access_key_id: AKIAIOSFODNN7EXAMPLE
aws_secret_access_key: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY

# 3. Save and exit

# 4. Use in playbook
- name: Configure AWS CLI
  template:
    src: aws-credentials.j2
    dest: ~/.aws/credentials
```

## Vault File Locations

**Current Repository:**
- `group_vars/all/vault.yml` - Global secrets for all hosts
- `~/.ansible_vault_pass` - Vault password (local only, not in git)

**Possible Locations:**
- `group_vars/<group_name>/vault.yml` - Group-specific secrets
- `host_vars/<hostname>/vault.yml` - Host-specific secrets
- `roles/<role_name>/vars/vault.yml` - Role-specific secrets

## Backup and Recovery

### Backup Vault Password

```bash
# Store in password manager (1Password, LastPass, etc.)
# OR encrypted backup
gpg -c ~/.ansible_vault_pass  # Creates ~/.ansible_vault_pass.gpg
```

### Recovery

```bash
# From password manager
echo "password-from-manager" > ~/.ansible_vault_pass
chmod 600 ~/.ansible_vault_pass

# From encrypted backup
gpg -d ~/.ansible_vault_pass.gpg > ~/.ansible_vault_pass
chmod 600 ~/.ansible_vault_pass
```

## Integration with Control Node

When deploying to remote hosts, the vault is automatically decrypted locally on the control node. Secrets are never stored unencrypted on remote hosts.

```bash
# Deploy with vault secrets
ansible-playbook deploy.yml --limit production

# Vault variables are available to all roles
# digitalocean_api_token, github_token, etc.
```

---

**Security Reminder**: Always treat vault passwords with the same care as the secrets they protect!
