# find-features — Iteration 1 Benchmark

## Per-eval results (with_skill)

| Eval | Pass rate | Notes |
|---|---|---|
| eval-1-nvim-file-nav | 7/7 (100%) | 6 suggestions, 2 existing wins found |
| eval-2-tmux-power-up | 7/7 (100%) | 8 suggestions, tpm correctly flagged as prereq |
| eval-3-mac-clipboard | 6/6 (100%) | 7 suggestions, 1Password existing angle surfaced |

All with-skill assertions passed. Suggestions were substantive and category-diverse.

## With-skill vs baseline

| Eval | With-skill time | Baseline time | With-skill tokens | Baseline tokens |
|---|---|---|---|---|
| eval-1 | 253s | 75s (3.4x faster) | 79k | 50k (1.6x lower) |
| eval-2 | 245s | 108s (2.3x faster) | 72k | 34k (2.1x lower) |
| eval-3 | 169s | 83s (2.0x faster) | 60k | 32k (1.9x lower) |
| **avg** | **222s** | **89s (2.5x faster)** | **70k** | **39k (1.8x lower)** |

## Observations

1. **Suggestion quality is similar.** In eval-1 the baseline arguably *beat* the
   skill — clearer narrative, concrete code snippets, explicit "stop and use it
   for a few days before adding a plugin" recommendation. The with-skill JSON
   format makes suggestions structured but not obviously better.

2. **Skill overhead is real.** 2.5x slower, 1.8x more tokens on average, for
   Phase 1+2 alone. The slowdown is partly race-condition rework (see #3)
   but mostly the plan-a-plan ceremony: Claude has to author JSON for
   session_cli, scan the full tools tree, serialize suggestions, then render
   markdown for the user anyway.

3. **Session state race is confirmed.** 3/3 with-skill agents hit it.
   One had to redo calls atomically; one watched `/tmp/suggestions.json` get
   stomped. A real bug, not a test artifact — the single
   `state/current-session.json` file has no isolation.

4. **scan_tools is overkill for Phase 2.** The script dumps all 109 tools
   every time. The agents still ended up doing targeted Grep/Read on the
   specific tool dirs they cared about (nvim lua tree, tmux.conf.j2) because
   the scan's file-content cap (20KB) clipped the interesting parts.

5. **The structured workflow shines in the abstract but wasn't tested where
   it matters.** Phase 1+2 is the part the baseline can replicate. Phase 3
   (install → demo → approve/reject → promote, with manifest-tracked undo)
   is where scripts earn their keep — and the evals explicitly stopped short
   of it because there's no live user to pick.
