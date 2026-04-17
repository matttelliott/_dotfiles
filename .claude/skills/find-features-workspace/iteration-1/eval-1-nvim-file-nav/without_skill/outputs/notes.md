# Exploration notes

## Goal parsing

User's request: "jump back to recently-edited files in nvim without leaving home row."

Key constraints:
- "Recently-edited" — implies cross-session recency, not just currently-open buffers (though buffers may satisfy in practice)
- "Without leaving home row" — rules out arrow keys, function keys, mouse; favors `<leader>` chords and home-row letters
- "Currently using `:e` with tab-completion" — pain point is (a) typing `:e ` prefix, (b) tab-completion cycling through irrelevant entries

They want a keystroke-efficient picker for recent files.

## Repo exploration

Started at `/Users/matt/_dotfiles/tools/neovim/`:

- `install_neovim.yml` — Ansible playbook (didn't read, not relevant to the feature request)
- `nvim/init.lua` — main config, kickstart.nvim based
- `nvim/lua/custom/plugins/` — user's customizations
- `nvim/lua/kickstart/plugins/` — kickstart's optional modules

## Findings in init.lua

Leader is `<Space>`. Telescope is installed with these relevant keymaps already:

| Keymap | Action | Relevant? |
|---|---|---|
| `<leader><leader>` | `builtin.buffers` | Yes — open buffers |
| `<leader>s.` | `builtin.oldfiles` | Yes — recent files across sessions |
| `<leader>sf` | `builtin.find_files` | Partial — all files, not "recent" |

`mini.nvim` is installed (via `echasnovski/mini.nvim`) — currently uses `mini.ai` and `mini.statusline`. `mini.visits` is part of the same package but not configured.

## Findings in custom/plugins/keymaps.lua

Extra user keybinds:
- `<leader>o` → `Telescope find_files`
- `<leader>/` → `Telescope live_grep`
- `<leader>w` → `wa`
- `jk`/`kj`/etc → `<Esc>` in insert mode

No mapping for `oldfiles` with a shorter chord, and nothing harpoon-like.

## Rejected-plugins notes in init.lua

Bottom of init.lua lists rejected plugins:
- nvim-spectre (keybind conflicts)
- nvim-ufo
- nvim-treesitter-context

No mention of harpoon/grapple being rejected — so those are fair to suggest.

## Reasoning about suggestions

The user is almost certainly unaware `<leader><leader>` and `<leader>s.` exist — they said they're using `:e`. That means step 1 is literally "here's what you already have." This is the highest-value, zero-cost answer.

For next-level upgrades, the ladder goes:
1. Rebind oldfiles to a shorter chord (trivial, one-line change)
2. Enable `mini.visits` (already-installed dependency, no new install)
3. Add harpoon/grapple (new plugin, but the gold-standard answer for this exact workflow)
4. Add telescope-frecency (new plugin, refines oldfiles ordering)

Ordered the suggestions from lowest-effort to highest-effort, and from "you already have it" to "brand new tool." This respects the repo's layering convention and the user's time.

## Files referenced

- `/Users/matt/_dotfiles/tools/neovim/nvim/init.lua` (Telescope keymaps at lines 430-463)
- `/Users/matt/_dotfiles/tools/neovim/nvim/lua/custom/plugins/keymaps.lua` (custom keybinds)
- `/Users/matt/_dotfiles/tools/neovim/README.md` (context only, no relevant info for this request)
