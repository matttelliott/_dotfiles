# I/O contract for scriptified skills

Every script this skill produces speaks the same envelope so that humans, the
agent, and *other scripts* can all consume it without special-casing. Hold this
contract even when it's slightly more verbose than a one-off would need — the point
is uniformity across skills.

## Invocation shape

```
python scripts/<skill>.py <subcommand> [flags]
```

- `gather` — read-only. Runs every collector and prints the output envelope. Safe
  to run anytime, any number of times. **No mutations here.**
- `schema` — prints the JSON Schema for the `gather` output to stdout. Lets callers
  validate, and lets you verify your own output in step 7.
- `<action>` — one subcommand per mechanical mutation (`branch`, `comment`,
  `apply`, `label`…). Each takes explicit flags, does one deterministic thing, and
  prints a small JSON result (`{"ok": true, …}`).

Flags use `argparse`. Prefer explicit named flags (`--issue 42`) over positional
args so calls are self-documenting in the SKILL.md.

## Output envelope (stdout)

`gather` always prints exactly one JSON object:

```json
{
  "skill": "forge-workflow",
  "version": 1,
  "data": { "...": "skill-specific gathered state" },
  "errors": []
}
```

- `skill` — the skill name. This is the merge key when composing skills, so it must
  be unique and stable.
- `version` — bump when you change `data`'s shape, so consumers can detect drift.
- `data` — the gathered context. Namespace by concern (`prs`, `issues`, `git`,
  `lint`). Use arrays of objects with stable keys, not loose prose strings, so the
  agent reasons over fields instead of re-parsing text.
- `errors` — array of `{"source": "...", "message": "..."}` for collectors that
  failed. A failing collector should degrade gracefully: record the error here,
  leave its `data` slice empty/null, and keep going. A half-gathered result the
  agent can reason about beats a hard crash.

Action subcommands print a smaller object: `{"ok": true, "skill": "<name>",
"action": "<sub>", "result": {…}}` (or `"ok": false` with an `"error"`).

## Composition

A composite skill (`/fix-code-quality` from `/fix-lint` + `/fix-formatting`) runs
each child's `gather` and merges by `skill`:

```json
{ "fix-lint": { "...envelope..." }, "fix-formatting": { "...envelope..." } }
```

Because each child namespaces its own `data` and carries its own `skill`/`errors`,
there are no collisions and no child needs to know it's being composed.

## state.json

For state that must persist between invocations, write `scripts/state.json`:

```json
{ "skill": "watch-pr", "version": 1, "state": { "last_seen": { "42": "open" } } }
```

- Keep it small and namespaced under `state`.
- A missing or malformed file means "no prior state" — return a default, never
  raise. State should never be load-bearing for correctness; it's an optimization
  (e.g. "what changed since last run"), so the skill must still work if it's wiped.

## action-items.json

The honest accounting of what stayed manual. Written alongside the script:

```json
{
  "skill": "forge-workflow",
  "items": [
    {
      "id": "decide-merge-conflict-resolution",
      "kind": "judgment",
      "summary": "Choosing how to resolve a merge conflict needs reading both sides.",
      "where": "SKILL.md: 'Resolving a PR's merge conflicts'",
      "reason": "Outcome depends on intent, not a mechanical rule."
    }
  ]
}
```

- `kind` is one of `judgment` (needs a brain), `policy` (deterministic but a
  human-owned rule the agent must honor, e.g. never-close), or `unautomatable`
  (mechanical in principle but blocked — missing API, interactive-only tool, etc.;
  say why in `reason`).
- `where` points back into the skill so a developer can find it.
- This list is what someone reads to know exactly how autonomous the skill now is.
