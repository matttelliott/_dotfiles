# Jumping back to recently-edited files in Neovim

You want to jump back to recently-edited files without leaving home row, instead of `:e <Tab>`. Good news: your config already has most of what you need. Here's a layered set of suggestions, starting with stuff that's already installed.

## Already installed — just use these

Your config (`tools/neovim/nvim/init.lua`) is based on kickstart.nvim and ships Telescope with useful pickers already bound. With `<leader>` mapped to `<Space>`, these are all home-row-friendly:

### 1. `<Space><Space>` — Switch between open buffers (fastest option)

```lua
vim.keymap.set('n', '<leader><leader>', builtin.buffers, ...)
```

If the file you want is still open as a buffer, this is the fewest keystrokes. Double-tap space, fuzzy-type a few letters, hit enter. No tab completion needed.

### 2. `<Space>s.` — Search recent files (oldfiles)

```lua
vim.keymap.set('n', '<leader>s.', builtin.oldfiles, ...)
```

This is Telescope's `oldfiles` picker — it reads Neovim's `:oldfiles` list (persisted across sessions via `shada`). This is the closest match to your request: "recently-edited files across sessions." Press `<Space>` then `s` then `.` and fuzzy-find.

### 3. `<Space>o` — Open any file in project (fuzzy)

Your `custom/plugins/keymaps.lua` adds:

```lua
{ '<leader>o', '<cmd>Telescope find_files<cr>', desc = '[O]pen file' },
```

Not "recent" specifically, but so much faster than `:e <Tab>` that you may not miss "recent" as often.

### 4. `Ctrl-o` / `Ctrl-i` — Jump list (built-in)

Pure Vim, no plugin needed. `<C-o>` jumps backward through the jump list (includes file switches), `<C-i>` forward. Great for "I was JUST in this file."

### 5. `Ctrl-^` — Swap to alternate file (built-in)

Toggles between current and previous buffer. Single keystroke. If you bounce between two files, this beats everything.

## Quick win: shorter keybind for recent files

`<Space>s.` is three keys. If you want a two-key chord for recents, add one line to `tools/neovim/nvim/lua/custom/plugins/keymaps.lua`:

```lua
{ '<leader>r', '<cmd>Telescope oldfiles<cr>', desc = '[R]ecent files' },
```

Or bind `<leader>e` (matches your muscle memory from `:e`).

## New plugin suggestions (if builtins aren't enough)

### harpoon (ThePrimeagen/harpoon)

The cult favorite for this exact problem. You "pin" 1-4 files to a named list, then jump to each slot with a single chord (e.g. `<leader>1`, `<leader>2`). Unlike `oldfiles`, *you* decide what's in the list — no noise. Zero fuzzy-match needed: just muscle memory for slot numbers.

- Pro: Insanely fast once pinned. Home row friendly.
- Con: Manual curation; not automatic "recency."

### grapple.nvim (cbochs/grapple.nvim)

Same concept as harpoon, more modern API, scoped per-project or per-git-branch automatically. Good if you work across many repos.

### mini.visits (part of echasnovski/mini.nvim — already installed!)

You already have `mini.nvim`. `mini.visits` tracks file visits per project and surfaces recent/frequent files. Since the dependency is already there, enabling it is one `require('mini.visits').setup()` call plus a keybind. Low-cost experiment.

### telescope-frecency.nvim

A Telescope extension that ranks files by frecency (frequency + recency) instead of pure recency. Drop-in if `oldfiles` ordering feels noisy.

## My recommendation

Try this order:

1. **Right now, no changes:** start using `<Space><Space>` (buffers) and `<Space>s.` (oldfiles). These solve 80% of the problem.
2. **If you want a shorter chord:** add a `<leader>r` or `<leader>e` mapping for oldfiles (one-line change in `keymaps.lua`).
3. **If you want curated pinning instead of recency:** try `harpoon` or explore the already-installed `mini.visits`.
4. **If oldfiles ordering bugs you:** add `telescope-frecency`.

Stop and use it for a few days before adding a plugin — you may find the built-ins are all you need.
