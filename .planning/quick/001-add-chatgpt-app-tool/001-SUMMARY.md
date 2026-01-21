---
quick: 001
completed: 2026-01-21
commit: pending
---

# Quick Task 001: Add ChatGPT Desktop Linux Support

**Task:** Add Linux support (Debian/Arch) to ChatGPT Desktop tool and run playbook

## What Was Done

1. Discovered ChatGPT Desktop tool already existed with macOS-only support
2. Found that official OpenAI ChatGPT app doesn't support Linux yet
3. Added Linux support using [lencx/ChatGPT](https://github.com/lencx/ChatGPT) AppImage
4. Ran playbook successfully on local Arch Linux machine

## Changes

**Modified:** `tools/chatgpt-desktop/install_chatgpt-desktop.yml`

Added tasks for Linux (Debian + Arch):
- Check if already installed
- Download AppImage tarball from GitHub releases
- Extract tarball
- Create /opt/chatgpt-desktop directory
- Copy AppImage to /opt/chatgpt-desktop/chatgpt
- Create symlink at /usr/local/bin/chatgpt

## Verification

```
PLAY RECAP
desktop: ok=7 changed=2 unreachable=0 failed=0

Installed to: /opt/chatgpt-desktop/chatgpt
Symlink: /usr/local/bin/chatgpt
```

## Notes

- The macOS version uses official OpenAI ChatGPT app via Homebrew
- Linux version uses lencx/ChatGPT (unofficial but widely used)
- Host groups remain: `with_gui_tools:&with_login_tools:&with_ai_tools`

---
*Quick task 001 completed: 2026-01-21*
