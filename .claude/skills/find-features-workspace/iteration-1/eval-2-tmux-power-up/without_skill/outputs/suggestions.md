# tmux "Cockpit" — Feature & Plugin Suggestions

Goal: make tmux feel powerful — persistent sessions, effortless pane resizing, and a richer status bar (git + system info).

Current state (from `tools/tmux/tmux.conf.j2`):
- Prefix remapped to `C-a`, vi copy-mode, mouse on.
- TokyoNight-styled status bar with hostname, session, date/time, battery.
- Repeatable pane resize bound to `prefix C-h/j/k/l` (+5 cells).
- Vim-style pane nav (`h/j/k/l`), session switcher on `prefix s`.
- No plugins installed (no `tpm`, no `@plugin` entries in conf).
- No session persistence across reboots.
- No git info in status bar.
- No cross-app (vim/tmux) pane navigation.

Below: three tiers — existing features you may be underusing, plugins that bolt onto tmux, and brand-new tools worth adopting.

---

## Tier 1 — Leverage what's already configured

You already have these, but they may be underused:

1. **`prefix s` session tree (`choose-tree -ZsO name`)** — zoomed, sorted-by-name session picker. Faster than detach+attach for juggling projects.
2. **Click the status-left segment** — bound to `choose-tree` via `MouseUp1StatusLeft`. A literal cockpit-style click-to-switch.
3. **Click the status-right (battery/time)** — opens a `themesetting` popup. Shows the popup pattern you can extend for other HUDs (see new bindings below).
4. **Repeatable resize (`-r` flag)** — after `prefix C-h`, just keep tapping `C-h/j/k/l` without re-prefixing. Many users miss this.
5. **`pane_current_path` splits** — `prefix "` and `prefix %` already inherit cwd.
6. **50k scrollback** — already generous; combine with `prefix [` + vi search (`?`/`/`) for log hunting.

---

## Tier 2 — Plugins to add (via tpm)

Install **tpm** (Tmux Plugin Manager) first — one block in `tmux.conf.j2` plus an Ansible git-clone task. Then layer these:

### Session restoration (the headliner)
1. **`tmux-plugins/tmux-resurrect`** — save/restore sessions, windows, panes, working dirs, and even running programs (`vim`, `nvim`, `ssh`) across reboots. Bindings `prefix C-s` save, `prefix C-r` restore.
2. **`tmux-plugins/tmux-continuum`** — auto-saves every 15 min and auto-restores on tmux start. Pair with resurrect. Set `@continuum-boot 'on'` to auto-launch tmux at login.

### Smarter navigation / pane handling
3. **`christoomey/vim-tmux-navigator`** — `C-h/j/k/l` moves between nvim splits and tmux panes seamlessly (no prefix needed). Huge cockpit upgrade since you already use nvim.
4. **`tmux-plugins/tmux-pain-control`** — sensible defaults for pane splitting/resizing/swapping (`prefix H/J/K/L` resize by 5, `prefix |` and `prefix -` for splits that keep cwd, `prefix <` / `prefix >` to swap windows left/right).
5. **`sainnhe/tmux-fzf`** — fzf-powered menus for sessions, windows, panes, keybindings, commands. `prefix F`.
6. **`omerxx/tmux-sessionx`** — modern fzf session manager with previews; better than `choose-tree` once you get used to it.

### Copy-mode / clipboard
7. **`tmux-plugins/tmux-yank`** — `y` in copy mode sends to system clipboard (works on macOS + Linux Wayland/X11). You already have `pbcopy` wired for macOS; this generalises it.
8. **`tmux-plugins/tmux-copycat`** — regex search in scrollback, jump to URLs/hashes/files (`prefix C-u` for URLs, `prefix C-f` for filenames).
9. **`fcsonline/tmux-thumbs`** — vimium-like hint overlay to copy any on-screen token with a single keystroke. Massively speeds copying hashes, URLs, filenames.
10. **`tmux-plugins/tmux-open`** — press `o` on a selected URL/path in copy mode to open it.

### Status bar (git + system info)
11. **`tmux-plugins/tmux-cpu`** — exposes `#{cpu_percentage}`, `#{cpu_fg_color}`, `#{ram_percentage}`, `#{gpu_percentage}` for status-right.
12. **`tmux-plugins/tmux-battery`** — cleaner battery display than the current `pmset | grep` hack; cross-platform.
13. **`tmux-plugins/tmux-online-status`** — internet up/down indicator (`#{online_status}`).
14. **`tmux-plugins/tmux-net-speed`** — live up/down kbps.
15. **Git info in status-left** — two options:
    - `kristijanhusak/tmux-simple-git-status` — shows `branch` and dirty-count in the status bar.
    - DIY one-liner: `#(cd #{pane_current_path} && git rev-parse --abbrev-ref HEAD 2>/dev/null)` — no plugin needed.
16. **`catppuccin/tmux` / `dracula/tmux`** — turnkey themes with built-in git/cpu/battery widgets if you want to replace the hand-rolled TokyoNight block with something more feature-rich.

### Extras that feel "cockpit"
17. **`27medkamal/tmux-session-wizard`** — popup wizard: new-session-from-dir, switch, kill. Works with zoxide.
18. **`MunifTanjim/tmux-mode-indicator`** — prompt mode ("PREFIX/COPY/SYNC") segment in status bar.
19. **`laktak/extrakto`** — fuzzy-pick any text (path, URL, word) from any pane's buffer and paste or copy it.

---

## Tier 3 — New tools to install (sibling to tmux)

1. **`sesh` (joshmedeski/sesh)** — Go-based smart session manager over tmux. Reads zoxide + tmuxinator configs, fzf UI, zero config to start. Replaces `choose-tree`.
2. **`zoxide`** — if not present, pairs with sesh + tmux popups for "jump to project → new session".
3. **`tmuxinator` or `smug`** — declarative, per-project layouts (`tmuxinator start myapp` opens 3 windows with preset panes and commands). `smug` is a Go re-implementation, no Ruby dep.
4. **`gitmux` (arl/gitmux)** — dedicated binary that emits a rich git status string for tmux status-right (branch, ahead/behind, staged/unstaged counts, stash count). Drop-in: `set -g status-right '#(gitmux -cfg ~/.gitmux.conf "#{pane_current_path}")'`.
5. **`zjstatus`-style widgets** — not applicable (zjstatus is Zellij), but worth mentioning if you ever consider Zellij as a tmux alternative (built-in layouts, session persistence, status bar — no plugin juggling).
6. **`tmate`** — fork of tmux for pair-programming/remote sharing via SSH. Nice to have alongside, not a replacement.
7. **`overmind` / `hivemind`** — Procfile runners that play well with tmux for starting multi-process dev stacks.

---

## Recommended "MVP cockpit" bundle

If you want the highest value for the least config churn, install these 6 together:

1. `tpm` (required to load plugins)
2. `tmux-resurrect` + `tmux-continuum` — session restoration
3. `vim-tmux-navigator` — seamless nvim<->tmux motion
4. `tmux-pain-control` — better defaults for splits/resize/swap
5. `gitmux` (binary) — rich git info in status-right
6. `sesh` (binary) — fzf session switcher, much nicer than `choose-tree`

That gives you: reboot-survival, keyboard-native pane motion, cleaner resize, git at a glance, and instant project switching. Everything else in Tier 2 is optional polish.

---

## Integration notes for this repo

- Add a `tools/tmux/plugins/` convention or keep plugin list inside `tmux.conf.j2` with `@plugin` lines; `install_tmux.yml` should `git clone` tpm into `~/.tmux/plugins/tpm` and run `~/.tmux/plugins/tpm/bin/install_plugins` non-interactively.
- Per CLAUDE.md, any new glyphs in the status bar must be added as `{{ var }}` Jinja variables using `"\uXXXX"` escape sequences — do not paste PUA characters directly.
- `sesh` and `gitmux` each deserve their own `tools/sesh/` and `tools/gitmux/` directories following the standard per-tool Ansible layout (Homebrew + apt/pacman branches).
- For `vim-tmux-navigator` to work, the matching plugin must also be added on the neovim side (`tools/neovim/nvim/init.lua`).
