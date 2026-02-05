# Deep Rock Galactic Config

Manages DRG settings and mods via Ansible. Hardware-specific settings per-host, shared QoL settings as defaults.

## Deploy

```bash
ansible-playbook tools/drg/install_drg.yml --connection=local --limit desktop
```

## Desktop Settings (Ryzen 9 7900X, RTX 4070 Ti, 4K)

| Setting | Value | Notes |
|---------|-------|-------|
| Resolution | 3840x2160 | Native 4K |
| FOV | 100 | Max comfortable |
| DX12 | Enabled | Via VKD3D-proton → Vulkan |
| DLSS | Auto | Let GPU decide |
| Shading Quality | 3 | Max |
| Ragdoll Quality | 2 | Max |

Settings defined in `inventory.yml` under `desktop` host.

## Mods

Mods managed via mod.io integration. IDs stored in `inventory.yml`.

### Enabled

| Mod | What it does |
|-----|--------------|
| DRGLib | Required dependency for many mods |
| Miracle Mod Manager | Mod management framework |
| Mod Hub | Press **H** to open mod settings UI |
| Brighter Objects | Better resource visibility |
| Steeve and Bot Better Visibility | See tamed bugs + bots easier |
| Glowing Equipment | Equipment glows in dark |
| Better Explosion Range Indicator | See C4 blast radius |
| rancor's Rig HUD | Extra HUD info while drilling |
| Combined Resources | Shows team's total undeposited resources |
| Alternate Player List UI | Better player list |
| Ammo percentage indicator | Ammo as percentage on screen |
| Sprint by Default | Hold to walk instead of hold to sprint |

### Disabled (available but off)

- Hazard Persistence Enjoyer - Auto-select default hazard
- MOTD + Stat Track - Chat messages
- SimpleMissionTimer - Speedrun timer
- Weapon Heat Crosshair - Heat indicator on crosshair
- Custom Killfeed - Kill notifications
- SimpleQOL - Various tweaks
- Show more promotion levels - Cosmetic
- Hold to Jump / Bhop - Bunny hopping

## Enabling/Disabling Mods

1. Edit `inventory.yml`, find `drg_mods:` under desktop
2. Change `"True"` to `"False"` or vice versa
3. Re-run playbook

Or use **Mod Hub** in-game (press **H**) to toggle without touching config.

## Files

| File | Purpose |
|------|---------|
| `GameUserSettings.ini.j2` | Jinja2 template, pulls vars from inventory |
| `cfg/GameUserSettings.ini` | Backup of original working config |
| `cfg/Engine.ini` | Engine paths (deployed as-is) |
| `cfg/Input.ini` | Input bindings (empty = defaults) |
| `install_drg.yml` | Ansible playbook |

## Other Hosts

Any machine in `with_games` group gets defaults:
- 1080p resolution
- DX11 (DXVK)
- No DLSS
- Same mods/FOV/keybinds

Override per-host by adding `drg_*` vars in `inventory.yml`.
