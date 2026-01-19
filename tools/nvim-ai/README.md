# nvim-ai

A separate Neovim configuration for AI-assisted coding that extends the base neovim setup.

## Overview

`nvim-ai` uses Neovim's `NVIM_APPNAME` feature to run a completely isolated instance that:

- **Inherits** the full base neovim config (LSP, telescope, treesitter, etc.)
- **Adds** AI-specific plugins on top
- **Maintains separate** plugin data, state, and cache directories

This approach keeps your main `nvim` config clean and fast, while `nvim-ai` can have heavier AI integrations without affecting your daily editing.

## How It Works

```
~/.config/nvim/          # Base neovim config (untouched)
~/.config/nvim-ai/       # Copy of base + AI plugins layer
    └── lua/custom/plugins/
        └── ai.lua       # AI plugin specifications

~/.local/share/nvim/     # Base neovim data
~/.local/share/nvim-ai/  # Separate data for nvim-ai (plugins, mason, etc.)
```

The Ansible playbook:
1. Copies the base `~/.config/nvim/` to `~/.config/nvim-ai/`
2. Overlays AI plugins from `tools/nvim-ai/nvim-ai/lua/custom/plugins/`
3. Installs a shell alias: `nvim-ai` → `NVIM_APPNAME=nvim-ai nvim`

## Usage

```bash
# Regular neovim (no AI plugins)
nvim

# Neovim with AI plugins
nvim-ai
```

## Adding AI Plugins

Edit `tools/nvim-ai/nvim-ai/lua/custom/plugins/ai.lua` and redeploy:

```bash
ansible-playbook tools/nvim-ai/install_nvim-ai.yml --connection=local --limit $(hostname -s)
```

### Recommended Plugins (Claude Code subscription)

These integrate with Claude Code CLI (no separate API token needed):

- [coder/claudecode.nvim](https://github.com/coder/claudecode.nvim) - WebSocket MCP protocol, same as official IDE extensions
- [greggh/claude-code.nvim](https://github.com/greggh/claude-code.nvim) - Terminal-based integration

### Plugins Requiring API Tokens

- [olimorris/codecompanion.nvim](https://github.com/olimorris/codecompanion.nvim)
- [yetone/avante.nvim](https://github.com/yetone/avante.nvim)
- [zbirenbaum/copilot.lua](https://github.com/zbirenbaum/copilot.lua)

## Why Separate Configs?

1. **Startup time** - AI plugins can slow down startup; keep `nvim` fast for quick edits
2. **Isolation** - AI plugin issues won't break your main editor
3. **Experimentation** - Try new AI plugins without risk
4. **Context** - Use `nvim` for trusted code, `nvim-ai` when you want AI assistance
