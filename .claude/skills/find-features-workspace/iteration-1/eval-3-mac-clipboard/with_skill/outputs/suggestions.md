# Clipboard-history suggestions for macOS

You said: _"give me a nicer way to browse my clipboard history on mac"_

Your repo doesn't currently have a clipboard manager under `tools/`, so most options are "new tool" picks. A couple of addon angles fall out of tools you already have (`fzf`, `tmux`, `1password`). Grouped by category, most likely first.

---

## New tools (brand-new `tools/<name>/`)

1. **sugg-1 — Maccy (recommended default)**
   Tiny open-source menu-bar clipboard manager. Homebrew cask, global hotkey (Cmd+Shift+C), fuzzy search. Lowest-friction pick for "nicer clipboard history."

2. **sugg-2 — Raycast**
   Full Spotlight replacement whose Clipboard History command handles text + images + files with rich previews, pins, and fuzzy search. Best if you'd also use a launcher.

3. **sugg-3 — CopyQ**
   Cross-platform, scriptable, GPL. One playbook could cover macOS plus your debian/arch hosts. UI is dated, but the most powerful option.

4. **sugg-7 — Clipy**
   Free, minimal, menu-bar. Has a snippet manager (reusable templates), which Maccy lacks. Good if you paste repeated phrases.

## Addons (extend something you already have)

5. **sugg-4 — fzf clipboard history (zsh widget)**
   Background `pbpaste` poller + fzf picker bound to e.g. Ctrl+Y. Terminal-only but uses only tools already in your repo. Zero GUI dependency.

6. **sugg-5 — tmux-yank + extrakto via TPM**
   Your tmux has no plugin manager yet. tmux-yank syncs copy-mode to the system clipboard; extrakto fuzzy-picks strings out of visible pane output. Complements a system manager — doesn't replace it.

## Existing (already installed, just use it)

7. **sugg-6 — 1Password Quick Access**
   `Cmd+Shift+Space` pops a fuzzy search over all your secrets with auto-clearing clipboard. Not a general history, but if most of what you paste is credentials it's a zero-install win.

---

Which would you like to try? You can pick any subset (and order) — e.g. "let's try 1, 4 first" or "just 2." If nothing here fits, say so and I'll regenerate.
