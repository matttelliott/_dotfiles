---
created: 2026-01-20T16:07
title: Fix themes and add default themes for each machine
area: config
files:
  - themes/_color.yml
  - themes/_font.yml
  - themes/_style.yml
  - inventory.yml
---

## Problem

Current theme system allows applying coordinated themes (color/font/style) across tmux/starship/neovim, but there are issues:

1. **Fix needed**: Theme system may have bugs or inconsistencies (needs investigation)
2. **Missing feature**: No per-machine default themes defined in inventory
   - Each machine could have its own preferred theme (e.g., macbookair uses dark theme, desktop uses light theme)
   - Currently requires manual theme application on each machine

## Solution

Two-part task:

1. **Fix themes**: Investigate and fix any issues with theme application
   - Verify theme files work correctly
   - Check for missing variables or broken references
   - Test theme switching across tools

2. **Per-machine defaults**: Add theme configuration to inventory.yml host_vars
   - Define default color/font/style per host
   - Apply defaults during provisioning
   - Allow override mechanism for temporary theme changes

likely approach:

```yaml
# inventory.yml
macbookair:
  theme_color: dracula
  theme_font: sourcecodepro
  theme_style: round

desktop:
  theme_color: onedark
  theme_font: firacode
  theme_style: slant

default:
  theme_color: tokyonight
  theme_font: dejavu
  theme_style: angle
```

also want to create some pre-built combinations of themes that can be easily applied to non-inventoried machines via the themesetting tool
