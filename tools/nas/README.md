# NAS

Automount NAS shares from nas.home.lan using autofs.

## Shares

| Share | Mount Point |
|-------|-------------|
| home | ~/NAS/home |

## Configuration

Edit `nas_shares` in `install_nas.yml` to add more shares:

```yaml
nas_shares:
  - name: home
    mount_point: "{{ ansible_env.HOME }}/NAS/home"
  - name: media
    mount_point: "{{ ansible_env.HOME }}/NAS/media"
```

## Credentials

- macOS: Uses Keychain or prompts for credentials
- Linux: Edit `~/.nas-credentials` with your username/password

## Usage

Shares automount on access:

```bash
ls ~/NAS/home
```
