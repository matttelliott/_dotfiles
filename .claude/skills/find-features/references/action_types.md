# Install action types

An install plan is `{"actions": [...]}`. Each action is an object with a
`type` field. Supported types and their exact schemas:

## `brew` — Homebrew package (darwin only)

```json
{"type": "brew", "package": "lazygit"}
```

Silently skipped on non-darwin hosts (recorded in manifest).

## `apt` — apt package (debian/ubuntu only)

```json
{"type": "apt", "package": "lazygit"}
```

Runs with `sudo apt-get install -y`. Silently skipped elsewhere.

## `pacman` — pacman package (arch only)

```json
{"type": "pacman", "package": "lazygit"}
```

Runs with `sudo pacman -S --noconfirm`. Silently skipped elsewhere.

## `cmd` — arbitrary shell command

```json
{"type": "cmd",
 "cmd": "curl -fsSL https://foo/install.sh | bash",
 "reverse_cmd": "rm -rf ~/.foo"}
```

`reverse_cmd` is optional but strongly encouraged — without it, uninstall
can't undo this action and the user gets a "manual cleanup needed" warning.

## `git_clone` — git clone into a path

```json
{"type": "git_clone",
 "url": "https://github.com/tmux-plugins/tpm",
 "dest": "~/.tmux/plugins/tpm"}
```

Tilde and `$VAR` are expanded. If `dest` already exists, the clone is
skipped (and recorded), so rerunning a plan is idempotent. Uninstall does
`rm -rf <dest>`.

## `mkdir` — ensure a directory exists

```json
{"type": "mkdir", "path": "~/.config/foo"}
```

Records whether the directory predated the install. On uninstall, only
removes it if (a) we created it and (b) it's empty.

## `file_create` — write a new file

```json
{"type": "file_create",
 "path": "~/.config/zsh/lazygit.zsh",
 "content": "alias gg='lazygit'\n"}
```

**Fails if the file already exists** — this is deliberate, to catch cases
where two suggestions collide. If you genuinely mean to replace, split into
two actions: a `cmd` that moves the old file aside, then a `file_create`.
Parent dirs are created automatically. Uninstall deletes the file.

## `file_append` — append to a file

```json
{"type": "file_append",
 "path": "~/.zshrc",
 "content": "source ~/.config/zsh/lazygit.zsh"}
```

A trailing newline is added if missing. Records the exact appended chunk
and whether the file predated the install. Uninstall removes the chunk
from the file (string-match); if the chunk isn't found (user edited it
manually), uninstall reports "manual cleanup needed" rather than doing
something destructive.

---

## Design guidelines

- **One logical feature per plan.** A "try telescope.nvim" plan might be
  3 actions (install dep, add plugin dir, wire into init.lua); a plan that
  tries to install 4 unrelated tools is a phase-2 mistake.

- **Match repo conventions.** Put zsh configs at `~/.config/zsh/<tool>.zsh`
  and source them from `~/.zshrc`. Put nvim configs under `~/.config/nvim/`.
  This way the manifest paths align with where the Ansible playbook will
  drop files on approval.

- **Prefer structured types over `cmd`.** `file_create` knows how to undo
  itself; a `cmd` that echoes into a file does not. Only reach for `cmd`
  when there's no structured equivalent.

- **`reverse_cmd` everything you can.** If `cmd` is unavoidable, always
  author a `reverse_cmd` too.
