# Eval notes — find-features, eval-3 (mac clipboard)

## Run summary

- Phases executed: Phase 1 (intake), Phase 2 (scan + suggest). Stopped before any install per instructions.
- Session id: `20260417T214501Z`
- Intent registered: "give me a nicer way to browse my clipboard history on mac"
- 7 suggestions generated across all three categories (4 new, 2 addon, 1 existing).

## Observations about the repo (from scan)

- No clipboard manager currently present under `tools/` (checked against the 109 scanned tool names — none of maccy, raycast, copyq, clipy, alfred, paste, pastebot).
- Relevant already-installed tools:
  - `fzf` — could back an in-terminal clipboard picker; already has a TokyoNight-themed zsh config.
  - `tmux` — has no plugin manager yet, so no tmux-yank/extrakto integration; would need TPM.
  - `1password` — GUI app installed; its Quick Access covers the "paste credentials" slice of the problem for free.
  - `rectangle` — unrelated (window management) but confirmed macs-only host gating pattern to copy for a cask-only tool.

## Design decisions

- Ordered suggestions new-first because the natural-language request strongly implies the user wants a full clipboard-history experience, which none of their existing tools provide. Addon/existing options included so the cheapest wins (1Password, fzf) aren't missed.
- Maccy is the explicit "recommended default" because it's the most direct fit, cheapest to try, and matches repo conventions (single cask, macs-only host group like tools/rectangle/).
- Raycast ranks second because it's more ambitious (launcher replacement) and could re-orient the user's workflow beyond just clipboards; flagged that tradeoff in the rationale.
- Included CopyQ specifically to surface the cross-platform angle given the repo has debian and arch hosts, even though the prompt only mentions macOS.
- Did not include Paste/Pastebot (paid apps) — repo pattern strongly favors free/open source.

## Issues hit during the run

- A prior eval left a stale `/tmp/suggestions.json` in place; an initial `Write` failed (file existed; also wrong pre-read state), so the first `add-suggestions` call registered 6 old nvim-file-jumping suggestions instead of clipboard ones. Recovered by clearing the session, overwriting `/tmp/suggestions.json` with the correct array, and re-running `session_cli new` + `add-suggestions`. Final session state confirmed correct via `session_cli show`.
- The skill's scripts-run-from-skill-dir convention is a little fragile across Bash cwd resets — had to invoke `python3 -m scripts.X` carefully. No bugs in the scripts, just something to watch for.

## Stopped here

No install, no demo, no promote. Ready to hand to a user for selection.
