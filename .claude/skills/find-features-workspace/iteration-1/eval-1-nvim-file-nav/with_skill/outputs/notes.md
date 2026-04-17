# Eval notes — find-features with nvim file-nav request

## Scripts I ran
- `python3 -m scripts.session_cli clear --yes` — wipe prior state
- `python3 -m scripts.session_cli new --intent "..."` — start session (ran twice; see "awkwardness" below)
- `python3 -m scripts.scan_tools > /tmp/find-features-scan.json` — produced a 446 KB JSON dump of every `tools/<name>/` entry (one `tools` key at top with an array)
- `python3 -m scripts.session_cli add-suggestions --file /tmp/suggestions.json` — registered the 6 suggestions (also ran twice)

## Repo exploration I did beyond the scripted scan
The raw `scan_tools` dump gives the top-level `tools/<name>/install_*.yml` + `*.zsh` contents but doesn't recurse into nested lua configs. Since this intent was nvim-specific I did targeted digging:

- `Grep` for `telescope|oldfiles|harpoon|Recent|<leader>f` under `tools/neovim/nvim/` — discovered telescope is already configured with lots of pickers bound.
- `Read` of `tools/neovim/nvim/init.lua` lines 430-464 — exact keymaps the user has today: `<leader>s.` → `oldfiles`, `<leader><leader>` → `buffers`, `<leader>o` → `find_files`, etc.
- `Read` of `tools/neovim/nvim/lua/custom/plugins/keymaps.lua` — the right place for the user to add their own binding without fighting the upstream kickstart config.
- Peeked at `oil.lua` and `nvim-ai/README.md` for context on the broader nav surface.

That extra digging was what let suggestions #1 and #2 be "existing" rather than forcing everything into "new" — a big value-add over the scan-only view.

## What was awkward / unclear

1. **Session state got clobbered repeatedly by something outside my control.** After my `new --intent "..."` call, `state/current-session.json` kept reappearing with a *different* intent ("give me a nicer way to browse my clipboard history on mac", and later a full tmux-cockpit suggestion list). Some other process was concurrently overwriting the session file mid-eval. I worked around it by having a single Python snippet atomically write both `state/current-session.json` and the output snapshot in one shot at the end. Worth noting: the skill has no locking — concurrent sessions silently trample each other.

2. **No `session_cli` command to set intent** — `new` resets everything. If a user realises they want to refine their intent mid-session, the only option is to start over (losing suggestions). A `session_cli set-intent --intent "..."` or `patch --field intent --value "..."` would help.

3. **`add-suggestions` requires round-tripping through a file.** Since my suggestions live in my head, writing JSON to `/tmp/suggestions.json` and then re-reading it is an extra step. A `--stdin` mode works (code supports `-`) but isn't documented in the SKILL.md example. Minor.

4. **`/tmp/suggestions.json` disappeared between bash calls.** Each Bash call resets working state; harmless but meant I had to re-emit the JSON. Using Python's stdlib to pipe direct to `session_cli add-suggestions --file -` would avoid `/tmp` entirely.

5. **Scan output is big (446 KB) and not navigable.** For nvim specifically, the interesting config is under `tools/neovim/nvim/lua/` which the scanner doesn't traverse. I had to do my own grepping. Fine in practice, but a Skill-level hint like "for tool-internal config, fall back to Grep/Read under `tools/<tool>/`" would save the next invocation a moment of wondering.

6. **The intent field being overwritten meant the rationales in the session file reference telescope/nvim while `intent` once briefly said "clipboard history on mac"** — that would be confusing to the user reading the state file. Reinforces point #1.

## What felt natural
- The three-bucket framing (existing / addon / new) maps nicely onto real suggestions and surfaces "you already have this" wins first.
- The scripts did their jobs: `scan_tools` is a solid starting point and `session_cli` has a clean API.
- Having the skill stop the eval at "present suggestions" was a natural breakpoint — the markdown rendered cleanly and the user would have an easy choice to make.

## What I'd change in the skill
- Add a `set-intent` subcommand.
- Document the stdin mode for `add-suggestions`.
- Add an optional `--deep` flag to `scan_tools` that dives into `tools/<tool>/` subdirectories (lua, configs, etc.), or at least a note in SKILL.md telling Claude to Grep/Read those directly for nvim/tmux/etc.
- Session-file locking (or at least a mtime check) so concurrent eval runs don't trample each other.
