---
created: 2026-01-21T03:41
title: Add WezTerm image paste script (clip2path) and keybinding configuration
area: config
files:
  - ~/.local/bin/clip2path
  - ~/.config/wezterm/wezterm.lua
---

## Problem

Claude Code on Linux with WezTerm doesn't support native image pasting like it does on macOS. Images need to be manually saved and referenced with file paths, which slows down workflow when working with screenshots or visual content.

## Solution

Add clipboard script and WezTerm keybinding:

1. Create `~/.local/bin/clip2path` script that:
   - Detects Wayland (wl-paste) or X11 (xclip)
   - Extracts images from clipboard to /tmp
   - Outputs file path prefixed with @ for Claude Code

2. Add Ctrl+Alt+V keybinding to wezterm.lua that:
   - Calls clip2path script
   - Sends output to terminal

References:
- https://picton.uk/blog/claude-code-image-paste-wezterm/
- Script handles both Wayland and X11 environments
