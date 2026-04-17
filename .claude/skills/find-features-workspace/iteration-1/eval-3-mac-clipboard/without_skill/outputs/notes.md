# Exploration notes

## Repo structure observations

- 109 tool directories under `/Users/matt/_dotfiles/tools/`.
- Standard pattern: `tools/<name>/install_<name>.yml` playbook, optionally `<name>.zsh` shell snippet and config files.
- macOS GUI apps are installed via Homebrew Cask with a `creates: /Applications/<App>.app` idempotency check. Reference: `tools/rectangle/install_rectangle.yml` (9 lines, minimal macOS-only) and `tools/1password/install_1password.yml` (cross-OS).
- Host groups include `with_gui_tools` — that's the right fit for a clipboard-manager Mac app.

## Existing clipboard-related bits (grep for clipboard|clip|pbcopy|pbpaste)

- `tools/tmux/tmux.conf.j2:59` — `bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel 'pbcopy'`. Tmux copy-mode pipes yanks into the system clipboard, but there is **no history layer** — each copy overwrites the last.
- `tools/wezterm/clip2path` — shell script for Linux `xclip` image-paste translation. Not relevant to macOS clipboard history.
- `tools/wezterm/wezterm.lua.j2:17` — references `clip2path` on Linux only.
- No tool directory named `maccy`, `raycast`, `paste`, `clipboard`, `clipper`, `flycut`, or similar. Confirmed no clipboard manager is currently deployed.

## macOS specifics

- `tools/macos/install_macos.yml` sets system prefs (hostname, SSH, WoL, Dock auto-hide, Finder hidden files). No clipboard-related settings. This is not where a clipboard manager would go — it belongs in its own `tools/<name>/` dir per the repo's per-tool convention.

## Why the user is asking

Default macOS clipboard is single-slot: each `⌘C` clobbers the previous one. User explicitly says "nicer way to browse my clipboard history" → they want persistent history + a UI to pick from it.

## Scope boundary

User said "stop before installing" so I'm only presenting options. When they pick one, the add would be:
1. New dir `tools/<name>/`
2. `install_<name>.yml` mirroring `tools/rectangle/install_rectangle.yml` (macOS-only Cask install)
3. Optionally add to `with_gui_tools` group membership if not already covered by hosts: `macs`
4. Optionally short `README.md`

## Candidates considered and why

Shortlist criteria: (1) installable via Homebrew Cask or formula for clean Ansible integration, (2) actively maintained, (3) reasonable license/price, (4) matches repo aesthetic (prefers OSS and CLI-friendly).

- **Maccy** — best fit for repo ethos (OSS, minimal, Homebrew Cask).
- **Raycast** — broader upgrade; would also let the user drop Spotlight.
- **Paste** — nicer UI but subscription conflicts with repo's OSS preference.
- **clipboard CLI / clipper+fzf** — CLI-native alternatives for terminal-centric workflow.
- **Flycut / Jumpcut** — mentioned for completeness (text-only, security-minded users).
- **ClipBook** — newer entrant, worth a mention.
- **Alfred** — listed but only relevant if Alfred is already in play.

## Did not use the find-features skill
Per instructions, this exploration was done manually (Glob, Grep, Read) without invoking `/find-features`.
