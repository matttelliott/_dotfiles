# Eval-2 notes — tmux power-up (with_skill)

## What I ran, in order

1. `python3 -m scripts.session_cli clear --yes`
2. Read `SKILL.md`, `references/action_types.md`, `references/playbook_conventions.md`.
3. `python3 -m scripts.session_cli new --intent "tmux feels really basic. I want to feel like my tmux is a cockpit..."` — session `20260417T214327Z`.
4. `python3 -m scripts.scan_tools > /tmp/find-features-scan.json` (446KB, 109 tools).
5. Filtered scan JSON in Python to inspect `tmux`, `starship`, `lazygit`, `git` entries. Read the full `tmux.conf.j2` to ground suggestions in what's already configured.
6. Authored 8 suggestions (1 existing, 5 addon, 2 new) and wrote `/tmp/suggestions.json` via a Python heredoc.
7. `python3 -m scripts.session_cli add-suggestions --file /tmp/suggestions.json` (count: 8).
8. Discovered a collision — a parallel eval (clipboard-history) had clobbered `state/current-session.json` between my `new` and `add-suggestions` calls. The intent in the session file was wrong.
9. Reran `clear --yes`, `new`, and `add-suggestions` back-to-back in a single Bash invocation. Session `20260417T214534Z` has correct intent and all 8 suggestions.
10. Copied session.json, wrote suggestions.md and notes.md into the outputs dir.

## Scan findings that shaped the suggestions

- `tools/tmux/tmux.conf.j2` already has: prefix C-a, vim-style pane nav (h/j/k/l), repeatable resize (Ctrl-h/j/k/l, 5 cells), mouse on, TokyoNight theme with powerline, session chooser on `prefix + s`, status-left with hostname + session, status-right with date/time + battery. No tpm, no resurrect, no git segment — exactly the gaps the user named.
- tmux README explicitly calls out the LLM-unsafe Nerd Font PUA glyphs and prescribes the `chr(0xE0xx)` Python pattern. I flagged this in `sugg-5` and will need to use it in Phase 3.
- fzf is installed (good prerequisite for `sesh`). No existing fuzzy-session tool.
- lazygit + starship templates show the repo's playbook style (brew/apt/pacman + `~/.config/zsh/<tool>.zsh` + zshrc sourcing). That's what promoted tools should match.

## What was awkward

- **Shared-session race.** `state/current-session.json` is a single file, so running multiple find-features sessions in parallel (e.g., evals in separate shells) clobbers each other. Had to redo `new`+`add-suggestions` atomically. If evals run concurrently, this bookkeeping layer needs per-process isolation.
- **`cd` reset between Bash calls.** Every invocation had to be from the skill dir; I used absolute paths and the `-m scripts.xxx` module form from the skill dir (cwd was already correct per env). Not a blocker but easy to forget.
- **Write tool required prior Read for `/tmp/suggestions.json`** (it had been written earlier by something). Worked around by generating via `python3` heredoc.
- **`bind -r` confusion in sugg-1 description.** `bind -r` means "repeatable" — after `prefix + Ctrl-h`, you can tap `h` again to continue resizing. I should demo that carefully in Phase 3 so the user actually feels the repeat.
- **The skill invocation preamble (`cd .claude/skills/find-features`) is stated but our harness already started there.** Fine, but worth noting that docs assume you're not already cwd'd in.

## Stopped here

Per instructions, stopped after presenting suggestions. No `select`, no `install_feature`, no `promote_to_playbook`. All 8 suggestions registered in the session; user (in a real run) would pick a subset and we'd enter Phase 3.
