---
name: merge-pr
description: Merge the open pull request / merge request for the current branch on the repo's forge — GitHub, GitLab, Gitea, or Forgejo. Checks that a PR exists, reports its status (checks, reviews, mergeable), and merges it via the appropriate CLI (`gh`, `glab`, `tea`). Use when the user asks to "merge this PR", "land this branch", "ship it", "merge the MR", or similar — regardless of which forge the remote points to.
---

# merge-pr

Merge the open pull request for the current branch. Complementary to
`create-pr`: that skill opens the PR, this one lands it. Works with GitHub,
GitLab (self-hosted included), Gitea, and Forgejo. Scripts handle forge
detection, status lookup, and CLI dispatch; Claude handles the judgment
calls (is it ready to merge? which merge method? bypass blockers?).

Run the scripts **from the repo root** (your current working directory) so
their `git` calls hit the right repo. Invoke them by absolute path — do
**not** `cd` into the skill directory.

---

## Phase 1 — Detect

```bash
python3 ~/.claude/skills/merge-pr/scripts/forge_detect.py
```

Returns JSON with `forge` (`github`/`gitlab`/`gitea`/`unknown`), `host`,
`owner`, `repo`, and whether the matching CLI (`gh`/`glab`/`tea`) is
installed.

**If `forge` is `unknown`:** ask the user which forge they use, then re-run
with `MERGE_PR_FORGE=github|gitlab|gitea` exported in the environment. For
self-hosted Gitea/Forgejo on an unusual hostname, you can also add the host
to `MERGE_PR_GITEA_HOSTS` (comma-separated).

**If `cli_installed` is false:** stop and tell the user. Don't try to
install it yourself — the required auth (`gh auth login`, `glab auth login`,
`tea login add`) isn't something you can do non-interactively.

---

## Phase 2 — Status

```bash
python3 ~/.claude/skills/merge-pr/scripts/pr_status.py --forge <forge>
```

Returns JSON with:
- `exists` — is there a PR/MR for the current branch?
- `number`, `url`, `title`
- `state` — `open` / `closed` / `merged`
- `is_draft`
- `mergeable` — `MERGEABLE` / `CONFLICTING` / `UNKNOWN`
- `merge_state` — forge-specific detail (e.g. `CLEAN`, `BLOCKED`, `BEHIND`, `DIRTY`)
- `checks` — `passing` / `failing` / `pending` / `none`
- `checks_detail` — counts per bucket
- `review_decision` — `APPROVED` / `CHANGES_REQUESTED` / `REVIEW_REQUIRED` / null
- `head_branch`, `base_branch`

**Bail-out cases:**
- `exists` is false → no PR to merge; suggest the user run `create-pr` first and stop
- `state` is `merged` → already landed; print the URL and stop
- `state` is `closed` → PR was closed without merging; tell the user and stop, don't reopen

**Warn (and ask the user before merging) when:**
- `is_draft` is true → PR is still a draft; ask if they want it marked ready + merged
- `mergeable` is `CONFLICTING` → resolve conflicts first; do NOT attempt the merge
- `checks` is `failing` → report which checks failed; confirm before merging
- `checks` is `pending` → offer `--auto` (auto-merge when checks pass) instead of blocking
- `review_decision` is `CHANGES_REQUESTED` → changes were requested; confirm
- `review_decision` is `REVIEW_REQUIRED` and repo requires reviews → confirm

When in doubt, surface the blockers and let the user decide. Prefer
`--auto` over waiting or forcing.

---

## Phase 3 — Merge

```bash
python3 ~/.claude/skills/merge-pr/scripts/pr_merge.py \
  --forge <forge> \
  --method <squash|merge|rebase> \
  [--delete-branch] \
  [--auto] \
  [--admin]
```

**Choosing a method:**
- Default to `squash` unless the user specified otherwise or `$MERGE_PR_METHOD`
  is set in the environment.
- If the repo's recent merge commits on the base branch follow a visible
  convention (e.g. linear history with rebase, or merge commits), match that.
- If the PR has a single well-crafted commit, `rebase` preserves it cleanly.
- If the PR has many WIP commits, `squash` is almost always right.

**Flags:**
- `--delete-branch` — delete the source branch after merge. Default off; turn
  on when the user indicates they're done with the branch. For GitHub this
  passes `--delete-branch`; for GitLab `--remove-source-branch`; for Gitea
  `--delete`.
- `--auto` — GitHub/GitLab only. Queues the merge for when checks pass.
  Useful when `checks` was `pending`.
- `--admin` — GitHub only. Bypasses branch protection rules (requires admin
  permission on the repo). Only pass this if the user explicitly asks to
  force/override protections.

The script prints JSON: `{success, method, url, already_merged, error}`.

**On success:** report the merge method used and the PR URL.
**On failure:** report the error verbatim. Common causes:
- Required checks haven't passed → offer `--auto`
- Required reviews missing → user needs an approval
- Branch protection blocking force operations → `--admin` if they have rights
- Merge conflicts → user must rebase/merge base locally and push

After a successful (non-`--auto`) merge, offer to switch the user back to
the base branch and pull:

```bash
cd <repo>
git checkout <base_branch>
git pull --ff-only
```

Only do this if the user agrees — they may have other local work on the
feature branch.

---

## What Claude owns

- Reading `pr_status` output and deciding whether the PR is ready to merge
- Picking the merge method (squash/merge/rebase) based on repo convention
- Deciding when to use `--auto`, `--admin`, or `--delete-branch`
- Surfacing blockers clearly to the user before acting

## What scripts own

- Forge detection from the remote URL
- Looking up the PR for the current branch and normalizing its status
- Invoking the forge CLI with the right flags and parsing results

## Environment overrides

- `MERGE_PR_FORGE=github|gitlab|gitea` — force forge type regardless of host
- `MERGE_PR_METHOD=squash|merge|rebase` — default merge method
- `MERGE_PR_GITEA_HOSTS=host1,host2` — self-hosted Gitea hostnames
- `MERGE_PR_FORGEJO_HOSTS=host1,host2` — self-hosted Forgejo hostnames
