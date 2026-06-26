---
name: make-script-for-skill
description: Take an existing skill and generate a Python automation script that front-loads everything mechanical, so a fresh agent can run the skill with the fewest possible decisions and tool calls. Use this whenever someone wants to "scriptify", "automate", "mechanize", or "speed up" an existing skill; cut a skill's tool calls or token cost; make a skill runnable autonomously or non-interactively; emit a skill's context/state as structured JSON; or make two skills composable — reach for it even when they just say "this skill does too much by hand" or "can we make <skill> faster" without naming a script. This transforms a skill that already exists; it is NOT for authoring a brand-new skill, nor for tuning a skill's trigger/description wording — use skill-creator for those.
---

# Make a script for a skill

Most skills make an agent re-derive the same context every run: a dozen `git`,
`tea`, `gh`, lint, or file-read calls just to learn the current state, then a few
mechanical mutations, with only a thin sliver of genuine judgment in between. That
re-derivation is slow, burns tokens, and is a place for the agent to drift.

This skill converts a **target skill** into a mostly-mechanical one. You write a
**Python script** that gathers all of that context in a _single call_ and prints it
as JSON, plus subcommands for the deterministic mutations. Then you rewrite the
target's `SKILL.md` so a fresh agent runs the script first and spends its reasoning
only on what actually needs a brain. Everything the script _can't_ do is emitted as
a structured list of action items, so nothing is silently dropped.

The win is concrete: a skill that used to open with fifteen read calls now opens
with one `python <skill-dir>/scripts/<skill>.py gather`, and the agent reasons over clean JSON
instead of raw command output.

## The one idea: classify every operation

Read the target skill end to end (its `SKILL.md` and every bundled resource), then
sort every operation it performs into exactly one of three buckets. This
classification _is_ the work — get it right and the rest is mechanical.

**Collectable context** — reads that gather state with no decision attached:
`git status`, `tea pr list --output json`, `tea issue <n> --output json`, "does
file X exist", "what's in config Y", a lint/test run whose output you parse. These
all move _into the script's `gather` command_. The agent should never run these by
hand again.

**Mechanical action** — a deterministic mutation, once a decision is made: create a
branch with a derived name, push, post a templated comment, apply a formatter,
write a label. These become _script subcommands_ (`branch`, `comment`, `apply`…)
the agent calls instead of hand-typing the command. The _decision_ to act stays
with the agent; the _doing_ moves to the script.

**Judgment** — anything needing a brain: deciding what to change, writing prose,
triage calls, resolving a conflict, choosing whether a gate is satisfied. This
**stays in the SKILL.md** as instructions, and every judgment point also goes into
the action-items JSON so it's an explicit, enumerable handoff rather than buried in
paragraphs.

When you're unsure which bucket something is in, ask: _could a script with no
model produce the right result every time?_ Yes → collectable or mechanical. No →
judgment. Borderline "it's deterministic but depends on a human policy" cases
(e.g. forge-workflow's "never close an issue") are **judgment/policy**: the script
can surface the relevant state, but the rule stays as prose the agent must honor.

## Preserve intent — this is a refactor, not a rewrite

The target skill's policies, gates, warnings, and tone are load-bearing. You are
changing _how_ the mechanical parts get done, not _what the skill is for_. The
never-close rule, the `ready-for-agent` gate, the "act as rb-bot not rbadmin"
constraint — none of that gets deleted. It gets _reframed_ around the script's
output: instead of "run these five `tea` reads to see the PR state," the SKILL.md
now says "the gathered JSON already has `prs[]` with each one's `mergeable` and
`state` — apply the never-close rule to them." If you find yourself dropping a
caveat because it didn't fit the script, stop: it belongs in the rewritten prose.

A good check: someone who knew the old skill should read the new one and feel it
got _sharper_, never that it forgot something.

## Workflow

1. **Locate and snapshot.** Read the target skill fully. Run `git -C <skill-dir>
status` (or check `git ls-files`) to learn whether it is under source control.
   **Committed → transform in place** (git is your undo). **Not committed → copy the
   skill directory to a working location first** and transform the copy, so the
   original is recoverable. Tell the user which path you took.

2. **Classify** every operation into the three buckets above. Jot the inventory
   down — it's the spec for the script and the action-items file.

3. **Design the I/O contract** before writing code. Decide the shape of the JSON
   `gather` prints, the subcommands and their flags, and what (if anything) needs to
   persist in `state.json`. Read `references/io-contract.md` for the conventions
   that keep outputs composable and schema-conformant — follow them, because
   composability (`/fix-lint` + `/fix-formatting` → `/fix-code-quality`) depends on
   every skill agreeing on the same envelope.

4. **Write the script.** Start from `assets/script_template.py` — it already has the
   subcommand dispatch, the JSON envelope, `state.json` helpers, the `run()`
   shell-out wrapper, and schema emission wired up, so you fill in collectors and
   actions rather than reinventing the skeleton each time. Copy it to
   `<skill-dir>/scripts/<skill>.py`. Conventions in `references/io-contract.md`;
   the essentials:
   - **Python 3, standard library only.** No pip installs, no venv. Shell out with
     `subprocess` for `git`/`tea`/`gh`/linters — anything bash could do, the script
     does via `run()`.
   - **JSON to stdout, diagnostics to stderr.** stdout must stay clean enough to
     pipe into `jq` or another script. Never print logs to stdout.
   - **Meaningful exit codes.** `0` success, `1` a real failure, and document any
     others. Callers (humans _and_ other scripts) branch on these.
   - **`gather` does no mutation.** It only reads. Side effects live in named action
     subcommands so running `gather` is always safe and repeatable.

5. **Rewrite the SKILL.md.** Put the script call up front ("run `python
<skill-dir>/scripts/<skill>.py gather` first — it returns everything below as JSON; don't
   re-gather by hand"). Replace each procedural read-sequence with how to _interpret_
   the corresponding JSON field. Point mechanical mutations at the subcommands. Keep
   every policy/gate/caveat (see _Preserve intent_). Trim the now-redundant "here's
   the exact command to run" prose — that knowledge now lives in the script.

6. **Emit the action items.** Write `<skill-dir>/scripts/action-items.json` listing
   every judgment point that stayed with the agent and anything you _couldn't_
   automate (and why). This is the honest accounting of what's still manual — see
   the schema in `references/io-contract.md`.

7. **Verify before declaring done.** Actually run the script. At minimum `python
<skill-dir>/scripts/<skill>.py --help` and `gather` must execute and print valid JSON
   (`... gather | python -m json.tool` should not error). If a real target
   environment is reachable (e.g. the forge repo), run `gather` there and sanity
   check the fields. Validate the output against the schema the script emits
   (`... schema`). Report what you ran and what it produced — don't claim it works
   without having run it.

## Composability and state

Two scriptified skills should compose without coordination. That works only if they
share an envelope: every `gather` prints `{"skill": "<name>", "version": 1, "data":
{…}}`, so a composite skill runs each child and merges by skill name
(`{"fix-lint": {…}, "fix-formatting": {…}}`) with no key collisions. The script must
also run standalone — a human typing `python <skill-dir>/scripts/fix-lint.py gather | jq .data`
is a first-class use, not an afterthought.

For state that must survive between runs (a `/watch-pr` remembering last-seen PR
status), use `<skill-dir>/scripts/state.json` via the template's `load_state` /
`save_state` helpers. Keep it small and namespaced under the skill name; treat a
missing or malformed file as "no prior state," never as an error.

## What good output looks like

- The rewritten SKILL.md opens with one script call, not a wall of read commands.
- `python <skill-dir>/scripts/<skill>.py gather` runs clean and pipes valid JSON.
- Every original policy/gate is still present, just reframed around the JSON.
- `action-items.json` enumerates exactly what still needs a brain — no more, no less.
- A fresh agent could run the skill end to end from the script's output plus the
  trimmed prose, making only genuine judgment calls.
