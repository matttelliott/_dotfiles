# Clipboard History for macOS — Suggestions

Your dotfiles currently have **no clipboard manager installed**. The only clipboard-related things in the repo are:

- `tools/tmux/tmux.conf.j2` pipes tmux copy-mode selections into `pbcopy`
- `tools/wezterm/clip2path` (Linux-only `xclip` helper for image paste)

So macOS is using the default single-slot system clipboard. Below are options, grouped by effort. All fit the repo's `tools/<name>/install_<name>.yml` pattern using Homebrew Cask, matching `tools/rectangle/install_rectangle.yml` and `tools/1password/install_1password.yml`.

---

## Recommended: GUI clipboard managers (Homebrew Cask)

### 1. Raycast (top pick if you want more than just clipboard)
- **What:** Spotlight replacement with a built-in, searchable clipboard history (text, images, files, links), pinning, smart paste, and rich previews.
- **Why:** Gives you a great clipboard browser *and* replaces Spotlight/launcher. Polished UI, actively maintained, free for the core features (clipboard history is in the free tier).
- **Install:** `brew install --cask raycast` — then enable the "Clipboard History" extension, assign a hotkey (e.g. `⌥⌘V`).
- **Group fit:** `with_gui_tools`.

### 2. Maccy (simple, free, open source — best pure clipboard tool)
- **What:** Lightweight menu-bar clipboard history manager. Fuzzy search, keyboard-driven, pinning, ignore rules, sensitive-data filtering, syncs via iCloud optionally.
- **Why:** Does one thing well. No bloat. ~20MB. Open source (MIT). Bound to `⇧⌘C` by default, fully rebindable.
- **Install:** `brew install --cask maccy`
- **Group fit:** `with_gui_tools`.

### 3. Paste (premium, polished, subscription)
- **What:** Beautiful horizontal clipboard-history grid, pinboards, iCloud sync across Mac/iOS.
- **Why:** Best-looking, most features; has rich text preview, categories. Downside: $15/yr subscription.
- **Install:** `brew install --cask paste`
- **Group fit:** `with_gui_tools`.

### 4. Alfred + Clipboard History (if you already use Alfred elsewhere)
- **What:** Alfred launcher with Powerpack's clipboard history feature.
- **Why:** Only worth it if you want Alfred for its many other features. Powerpack is a one-time paid upgrade.
- **Install:** `brew install --cask alfred` (Powerpack license bought separately)

### 5. Flycut (ancient but rock-solid, free, open source)
- **What:** Fork of the classic Jumpcut — plain-text only, minimal menu bar clip history.
- **Why:** Zero friction, totally free, text-only (which some people prefer for security). On the Mac App Store, plus `brew install --cask flycut`.

### 6. ClipBook (newer, free-tier available, searchable, image support)
- **Install:** `brew install --cask clipbook`

---

## CLI / terminal-focused options

### 7. `clipboard` (CLI, Homebrew formula `clipboard`)
- **What:** Cross-platform `cb` CLI with persistent history, named slots (e.g. `cb copy1`, `cb paste2`), search.
- **Why:** Great if you want to stay in the terminal; plays nicely with tmux and fzf.
- **Install:** `brew install clipboard`

### 8. `pbv` / `clipper` + `fzf` pipeline (DIY)
- **What:** `clipper` (Greg Hurrell) is a daemon that logs every copy into a plain file; pair with `fzf` (already installed per `tools/fzf/`) and bind to a shell keystroke to fuzzy-select past clips.
- **Why:** Fully customizable, lightweight, fits the CLI-heavy vibe of the repo.
- **Install:** `brew install clipper`, then a zsh function that does `clipper-file | fzf | pbcopy`.

### 9. tmux-yank + `tmux-copycat` / `tmux-fzf-url`
- **What:** Inside tmux, add a keybinding that opens an fzf picker over `~/.clipper.txt` (or `pbpaste` buffers) to re-paste.
- **Why:** Your tmux config already uses `pbcopy` for yanks — close the loop by letting you browse past yanks inside tmux.

---

## Comparison at a glance

| Tool        | Cost   | GUI | Images | Search | Sync      | Open source |
| ----------- | ------ | --- | ------ | ------ | --------- | ----------- |
| Raycast     | Free   | Yes | Yes    | Yes    | Pro only  | No          |
| Maccy       | Free   | Yes | Yes    | Yes    | iCloud    | Yes         |
| Paste       | $15/yr | Yes | Yes    | Yes    | iCloud    | No          |
| Alfred      | Paid   | Yes | Yes    | Yes    | Dropbox   | No          |
| Flycut      | Free   | Yes | No     | Basic  | No        | Yes         |
| ClipBook    | Free+  | Yes | Yes    | Yes    | Cloud(pro)| No          |
| clipboard cli | Free | No  | Yes    | Yes    | No        | Yes         |
| clipper+fzf | Free   | No  | No     | Yes    | No        | Yes         |

---

## My recommendation

If you want "the nicer way" with minimum fuss: **Maccy** — free, open source, fast, one-liner Homebrew install, perfect fit for `tools/maccy/install_maccy.yml` following the Rectangle playbook pattern.

If you're open to replacing Spotlight too: **Raycast** — covers clipboard history plus a lot more, and is a common upgrade path from Rectangle users.

Pick one when you're ready and I'll scaffold the Ansible playbook.
