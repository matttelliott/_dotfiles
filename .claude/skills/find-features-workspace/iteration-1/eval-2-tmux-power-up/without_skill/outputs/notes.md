# Exploration notes — tmux cockpit request

## Files examined

- `/Users/matt/_dotfiles/tools/tmux/install_tmux.yml` — installs tmux via brew/apt/pacman, templates `tmux.conf.j2` to `~/.tmux.conf`, reloads if changed. No tpm install, no plugin dirs.
- `/Users/matt/_dotfiles/tools/tmux/tmux.conf.j2` — hand-rolled TokyoNight statusline, prefix `C-a`, vi copy-mode, mouse on, 50k history, vim-style pane nav, repeatable resize (+5). No `@plugin` directives, no `run '~/.tmux/plugins/tpm/tpm'` line.
- `/Users/matt/_dotfiles/tools/tmux/README.md` — documents the PUA/Nerd-Font glyph policy (U+E0B0, U+F015 etc.) and warns LLMs to edit via escape sequences only.
- Directory listing of `/Users/matt/_dotfiles/tools/` — confirmed sibling tools present: `fzf`, `lazygit`, `starship`, `neovim`, `git`. No existing `sesh/`, `gitmux/`, `zoxide/`, `tmuxinator/`.

## Gaps vs. the "cockpit" brief

| Want                    | Today                                         | Gap                                              |
| ----------------------- | --------------------------------------------- | ------------------------------------------------ |
| Session restoration     | None                                          | Needs tmux-resurrect + tmux-continuum            |
| Easier pane resizing    | `prefix C-hjkl` (+5), repeatable              | Works but only one step size; no interactive mode |
| Status bar with git     | hostname, session, date, battery              | No git branch/dirty/ahead-behind                 |
| Cross-pane nav w/ nvim  | None                                          | Needs vim-tmux-navigator both sides              |
| Quick session switching | `prefix s` choose-tree + click status-left    | OK but no preview, no fuzzy                      |

## Key constraints noted from CLAUDE.md

- Nerd Font glyphs in `tmux.conf.j2` are PUA — any new status-bar icons must use Jinja vars + `"\uXXXX"` escapes, never pasted literally.
- Each new tool needs a `tools/<name>/install_<name>.yml` with `Darwin`/`Debian`/`Archlinux` branches.
- Playbooks should lint clean (`ansible-lint`).
- Use `creates:` for idempotent Homebrew shell commands.

## Decision points to raise with user before installing

1. Commit to **tpm**? Most plugin suggestions assume it. Alternative: vendor plugins as git submodules.
2. Keep hand-rolled TokyoNight statusline and add widgets, or swap to a theme plugin (catppuccin/dracula-tmux)?
3. Adopt **sesh** (replaces `choose-tree`) or stick with built-in?
4. Pair `vim-tmux-navigator` rollout on both tmux and neovim sides simultaneously.
5. `gitmux` binary vs. inline `#(git rev-parse ...)` shell — binary is richer but another tool to maintain.

## Sources / prior knowledge

Plugin list compiled from general tmux ecosystem knowledge (tmux-plugins org, prominent community plugins). No web fetches performed. Recommend verifying latest plugin URLs and `@plugin` names at install time.
