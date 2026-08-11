# users

Manages the accounts that should exist on a machine and which of them may sudo.

## Declaring accounts

On the admin's inventory entry:

```yaml
macmini:
  ansible_host: macmini.home.lan
  ansible_user: matt
  host_users:
    - name: matt
      role: admin
    - name: alice
      role: standard
      fullname: Alice Example # optional, defaults to name
      shell: /usr/bin/zsh # optional, Linux only
      ssh_keys: # optional
        - "ssh-ed25519 AAAA... alice@laptop"
```

| Field      | Required | Meaning                                            |
| ---------- | -------- | -------------------------------------------------- |
| `name`     | yes      | Account name                                       |
| `role`     | yes      | `admin` (may sudo) or `standard` (may not)         |
| `fullname` | no       | Display name / GECOS                               |
| `shell`    | no       | Login shell, Linux only (macOS accounts get `zsh`) |
| `ssh_keys` | no       | Public keys to authorize for the account           |

## Roles

`role` is the single source of truth for sudo rights. Each run reconciles both
directions, so demoting someone in inventory actually takes their access away:

| Platform | Admin group | Granted with              | Revoked with              |
| -------- | ----------- | ------------------------- | ------------------------- |
| macOS    | `admin`     | `dseditgroup -o edit -a`  | `dseditgroup -o edit -d`  |
| Debian   | `sudo`      | `user` module, `append`   | `gpasswd -d`              |
| Arch     | `wheel`     | `user` module, `append`   | `gpasswd -d`              |

`tools/sudoers` writes the matching `/etc/sudoers.d` drop-in for admins and
removes it for standard users.

## Passwords

Creating an account needs one. Never commit it — pass it at run time:

```bash
ansible-playbook setup.yml --limit macmini \
  -e '{"user_passwords": {"alice": "<password>"}}'
```

An account that does not exist and has no password available is reported and
skipped rather than created without one, so unattended self-update runs never
hang and never leave a passwordless account behind.

Passwords apply on creation only (`update_password: on_create`) — rerunning
never resets a password the user has since changed. Nothing here stores a
password on disk.

## Tags

Every task is tagged `system`. Standard users run `setup.yml` with
`--skip-tags system`, so account management is always the admin's job and
never runs from an unprivileged account.
