---
name: find-features
description: Help the user discover and try new features, plugins, or tools in their dotfiles repo. Given a described need ("I want better window management", "I wish pasting from clipboard was less painful", "how do I get fuzzy file search in nvim"), explore the repo's tools/, suggest existing features they may have missed, addons/plugins for installed tools, and brand-new tools to install, then help them try selected suggestions one by one — installing, demoing, tweaking, and either promoting approved features into the repo's Ansible layout or cleaning up rejected ones. Use this skill whenever the user wants to explore what's possible in this dotfiles repo, extend an existing tool, hunt for a feature, or evaluate a new tool before committing it. Trigger on phrases like "find me a way to…", "what tools do I have for…", "is there a plugin that…", "add a feature for…", "try X and see if I like it".
---

# find-features

Help the user find and adopt features in this Ansible-managed dotfiles repo. This
skill is a workflow driver: Python scripts handle the deterministic work
(scanning, installing, tracking, reversing, writing playbooks, staging in git),
and Claude handles the parts that actually need a brain (interpreting intent,
generating suggestions, authoring install plans and playbooks, walking the user
through demos).

## The four phases

1. **Intake** — capture what the user wants.
2. **Scan & suggest** — read the repo's `tools/`, then generate real suggestions in three buckets: already-present features, addons to existing tools, and brand-new tools.
3. **Trial loop** — for each selected suggestion, install → demo → configure → approve or reject. Approved suggestions get scaffolded into `tools/<name>/` and staged in git. Rejected ones get cleanly uninstalled.
4. **Done** — summarize what was adopted and what was tried, then stop.

Every phase uses `scripts/` for the bookkeeping. Each session is isolated by
its own id: session data lives at `state/sessions/<session-id>.json`, and the
currently-active session id is tracked in `state/active-session.json` so most
commands don't need to pass a session id explicitly. Install manifests live
under `state/manifests/<session-id>/<suggestion-id>.json`.

If you ever need to operate on a non-active session (e.g. recovering after a
crash, or running parallel sessions on purpose), every script accepts
`--session-id`. Use `session_cli list` to see what's on disk.

All script invocations below assume you run from the skill directory:
```
cd .claude/skills/find-features
```

---

## Phase 1 — Intake

Ask the user to describe what they want, in their own words. Don't make them
pre-categorize. Examples of valid intents:

- "I want a quicker way to jump between recent files in nvim"
- "my shell prompt feels slow, can we figure out why or replace it"
- "something to manage my dotfiles secrets"

Once they've answered, start a session:

```bash
python3 -m scripts.session_cli new --intent "user's words here"
```

That creates `state/current-session.json` with a fresh `session_id`.

---

## Phase 2 — Scan & suggest

### Gather raw material

```bash
python3 -m scripts.scan_tools > /tmp/find-features-scan.json
```

This dumps every `tools/<name>/` with its playbook, zsh config, templates,
etc. It is data, not recommendations — your job now.

### Generate suggestions

Read `/tmp/find-features-scan.json` and produce 3–8 suggestions. Cast a wide
net — the point is to surface options the user wouldn't have thought of.
Include three categories, in roughly this order of precedence:

- **`existing`** — the user already has this tool/feature installed but may not
  be using it. Example: they want fuzzy file search and `fzf` is already in
  `tools/fzf/` but not wired into nvim.
- **`addon`** — a plugin, extension, or config change to a tool that's already
  in the repo. Example: add `telescope.nvim` to the existing `tools/neovim/`.
- **`new`** — a brand-new tool that doesn't exist in the repo yet. Example:
  add `zellij` as a new `tools/zellij/`.

Each suggestion must be concrete enough to install. Vague ideas ("use better
keybindings") don't belong here — convert them into a specific thing first.

Write the suggestions as a JSON array, then register them:

Pipe the suggestions in via stdin (simplest, no temp file):

```bash
python3 -m scripts.session_cli add-suggestions --file - <<'JSON'
[
  {
    "id": "sugg-1",
    "type": "addon",
    "title": "Add telescope.nvim for fuzzy file & buffer search",
    "tool": "neovim",
    "rationale": "You already have fzf installed via tools/fzf/, but your nvim config doesn't wire into it. telescope.nvim is the modern nvim-native choice and integrates with your existing setup.",
    "references": ["https://github.com/nvim-telescope/telescope.nvim"]
  }
]
JSON
```

You can also write to a file and pass `--file /tmp/suggestions.json` if you'd
rather keep the JSON around for later inspection.

### Present to the user

Show the suggestions as a numbered list with short titles + one-line
rationales, grouped by type. Then ask which to try. The user can pick any
subset, in any order, and can skip.

When they've picked:

```bash
python3 -m scripts.session_cli select --ids sugg-1,sugg-3,sugg-2
```

Order matters — that's the trial order for phase 3.

---

## Phase 3 — Trial loop

For each selected suggestion, do this cycle. Do not start the next suggestion
until the current one is resolved (approved or rejected).

### 3a. Install

Author an install plan — a JSON document with an `actions` array. See
`references/action_types.md` for the supported action types and exact schemas.

Keep the plan minimal: the smallest set of steps that lets the user try the
feature. Save configs to paths that match the repo's conventions (zsh configs
under `~/.config/zsh/*.zsh`, nvim configs under `~/.config/nvim/`). Pick paths
that match what a promoted Ansible playbook would do later, so you're not
reshuffling on approval.

```bash
cat > /tmp/plan.json <<'JSON'
{
  "actions": [
    {"type": "brew", "package": "lazygit"},
    {"type": "file_create", "path": "~/.config/zsh/lazygit.zsh",
     "content": "alias gg='lazygit'\n"},
    {"type": "file_append", "path": "~/.zshrc",
     "content": "source ~/.config/zsh/lazygit.zsh"}
  ]
}
JSON
python3 -m scripts.install_feature --suggestion-id sugg-3 --plan /tmp/plan.json
```

The script prints a manifest path. On failure, the manifest captures what did
run so uninstall can still clean up partial state.

### 3b. Demo

Walk the user through trying the feature. This means concrete, runnable
commands they can paste — not abstract "try it out". For a shell tool, it
might be: "run `gg` in any git repo". For nvim, it might be: "open nvim and
hit `<leader>ff`". Include what a successful result looks like so they know
if it's working.

If they ask you to tweak something (theme, keybindings, enabled options),
make those changes directly on the host — edit the config file, reload the
shell/tmux/nvim, and have them test again. Keep iterating until they're
satisfied or ready to reject.

Every file you edit during tweaking should match the path the original
install put things at, so the same manifest still reverses the changes
cleanly. If you create *new* files during tweaking, add them to the manifest
by running a small `install_feature` plan whose only action is
`file_create` — that way a rejection still cleans them up.

### 3c. Approve or reject

Ask plainly: "want to keep this?"

**On approval** — promote into the repo:

Draft an Ansible playbook in the repo's established style. Look at existing
playbooks in `tools/` for reference (e.g. `tools/bat/install_bat.yml` for the
simple pattern, `tools/tmux/install_tmux.yml` for templated configs). Match
OS family handling (darwin/debian/arch), path conventions, and zshrc sourcing.

For a brand-new tool, the changeset creates `tools/<name>/install_<name>.yml`
and any supporting files. For an addon to an existing tool, the changeset
either adds a new file to `tools/<existing-tool>/` or replaces a specific
file there.

```bash
cat > /tmp/changeset.json <<'JSON'
{
  "tool_name": "lazygit",
  "mode": "new",
  "files": [
    {"path": "install_lazygit.yml", "write_mode": "create", "content": "- name: Install lazygit\n  hosts: all\n  ...\n"},
    {"path": "lazygit.zsh", "write_mode": "create", "content": "alias gg='lazygit'\n"}
  ]
}
JSON
python3 -m scripts.promote_to_playbook --changeset /tmp/changeset.json --suggestion-id sugg-3
```

This writes the files under `tools/<tool_name>/`, runs `git add` on them,
and marks the trial `approved` in the session. The user owns the commit —
don't commit for them.

After promoting, tell the user what was staged and suggest they diff
(`git diff --staged tools/<tool_name>/`) before moving on.

**On rejection** — clean up the host:

```bash
python3 -m scripts.uninstall_feature --suggestion-id sugg-3
```

The script reads the manifest and reverses each action in reverse order.
Some reversals are best-effort (a `cmd` action with no `reverse_cmd`
requires manual cleanup — the script will say so). Report the outcome to
the user so they know what state the host is in.

### 3d. Next

After approve or reject, confirm with the user: "move on to the next one
(`sugg-2: …`), or stop here?" If they want out, skip to Phase 4.

---

## Phase 4 — Done

When the user is finished:

- Summarize in 3–5 bullets: what was tried, what got approved (and staged),
  what got rejected, and any manual cleanup the user should do.
- Remind them about the staged git changes — they still need to review and
  commit.
- Leave the session file in place. If they want a fresh start later, they
  can run `python3 -m scripts.session_cli clear --yes`.

---

## What you (Claude) are responsible for

- **Intent understanding** — parse the user's natural-language request.
- **Suggestion generation** — use the scanned raw material plus your broader
  knowledge of the ecosystem. Don't artificially limit to what's mentioned
  in the scan; recommend plugins and tools the user hasn't heard of when
  they fit.
- **Install plan authoring** — the exact actions to run on the host.
- **Demo authoring** — concrete commands + expected outcomes.
- **Config tweaking** — edit files directly as the user iterates.
- **Playbook authoring** — write YAML that matches the repo's conventions
  by reading real examples in `tools/`.

## What the scripts are responsible for (don't reimplement these)

- Enumerating and summarizing `tools/` (`scan_tools.py`).
- Starting a session, recording suggestions, tracking selections
  (`session_cli.py`).
- Running install actions and writing a reversible manifest
  (`install_feature.py`).
- Reversing a manifest on rejection (`uninstall_feature.py`).
- Scaffolding the tool directory and staging in git
  (`promote_to_playbook.py`).

## Session state layout

```
state/
├── current-session.json                    # intent, suggestions, trials
└── manifests/
    └── <session-id>/
        └── <suggestion-id>.json            # install actions + outcomes
```

The scripts are the only things that write these files. You can read them
freely to recover context mid-session (e.g. if the user comes back later).

## References

- `references/action_types.md` — every install action type and its JSON schema.
- `references/playbook_conventions.md` — quick guide to authoring Ansible
  playbooks in this repo's style, with canonical examples.
