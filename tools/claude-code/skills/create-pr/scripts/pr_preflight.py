"""Gather everything the skill needs to draft a PR.

Outputs JSON: branch state, base branch, diff stat, commit log, truncated
diff, working-tree dirty flag. The skill prompts Claude (the model) with
this to produce the PR title and body — no API call is made here.

Also detects if a PR already exists for the current branch, so the caller
can skip creation and just print the URL.
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from dataclasses import dataclass, asdict, field


MAX_DIFF_CHARS = 30_000


def run(cmd: list[str], cwd: str | None = None, check: bool = True) -> str:
    result = subprocess.run(
        cmd, cwd=cwd, capture_output=True, text=True, check=False
    )
    if check and result.returncode != 0:
        raise RuntimeError(
            f"{' '.join(cmd)} failed ({result.returncode}): {result.stderr.strip()}"
        )
    return result.stdout


@dataclass
class Preflight:
    branch: str
    base: str
    has_commits_ahead: bool
    commits_ahead: int
    dirty: bool
    dirty_status: str
    upstream: str | None
    needs_push: bool
    existing_pr_url: str | None
    diff_stat: str
    commit_log: str
    diff: str
    diff_truncated: bool
    errors: list[str] = field(default_factory=list)


def current_branch(cwd: str) -> str:
    return run(["git", "rev-parse", "--abbrev-ref", "HEAD"], cwd).strip()


def resolve_base(cwd: str, branch: str, explicit: str | None) -> str:
    """Find the base branch to diff against.

    Preference order:
    1. --base argument
    2. $CREATE_PR_BASE env var
    3. gh's default base (github only) — skipped here; the creator handles it
    4. origin/HEAD symbolic ref (main/master)
    5. fall back to 'main', then 'master'
    """
    if explicit:
        return explicit
    env = os.environ.get("CREATE_PR_BASE")
    if env:
        return env
    try:
        head = run(
            ["git", "symbolic-ref", "refs/remotes/origin/HEAD"], cwd
        ).strip()
        if head.startswith("refs/remotes/origin/"):
            return head[len("refs/remotes/origin/") :]
    except RuntimeError:
        pass
    # fall back
    for cand in ("main", "master"):
        try:
            run(["git", "rev-parse", "--verify", cand], cwd)
            return cand
        except RuntimeError:
            continue
    raise RuntimeError(
        "Could not determine base branch. Pass --base or set $CREATE_PR_BASE."
    )


def check_dirty(cwd: str) -> tuple[bool, str]:
    out = run(["git", "status", "--porcelain"], cwd)
    return bool(out.strip()), out


def upstream_for(cwd: str, branch: str) -> str | None:
    try:
        return run(
            ["git", "rev-parse", "--abbrev-ref", f"{branch}@{{upstream}}"],
            cwd,
        ).strip()
    except RuntimeError:
        return None


def commits_ahead(cwd: str, base: str, head: str = "HEAD") -> int:
    try:
        out = run(["git", "rev-list", "--count", f"{base}..{head}"], cwd)
        return int(out.strip() or "0")
    except (RuntimeError, ValueError):
        return 0


def needs_push(cwd: str, branch: str, upstream: str | None) -> bool:
    if upstream is None:
        return True
    try:
        out = run(["git", "rev-list", "--count", f"{upstream}..HEAD"], cwd)
        return int(out.strip() or "0") > 0
    except (RuntimeError, ValueError):
        return True


def existing_pr_url(cwd: str, forge: str) -> str | None:
    """Best-effort lookup of an existing PR/MR for the current branch.

    Returns None on error or if no PR exists. The creator script also does
    its own check before creating — this is just for preflight reporting.
    """
    try:
        if forge == "github":
            out = run(
                [
                    "gh",
                    "pr",
                    "view",
                    "--json",
                    "url",
                    "--jq",
                    ".url",
                ],
                cwd,
                check=False,
            ).strip()
            return out or None
        if forge == "gitlab":
            out = run(
                [
                    "glab",
                    "mr",
                    "view",
                    "--output",
                    "json",
                ],
                cwd,
                check=False,
            ).strip()
            if not out:
                return None
            data = json.loads(out)
            return data.get("web_url") or None
        if forge == "gitea":
            # `tea` has no "view current branch PR" shortcut; skip preflight
            # check and let the creator handle duplicates.
            return None
    except Exception:
        return None
    return None


def collect(cwd: str, forge: str, base: str) -> Preflight:
    errors: list[str] = []
    branch = current_branch(cwd)
    ahead = commits_ahead(cwd, base)
    dirty, status = check_dirty(cwd)
    upstream = upstream_for(cwd, branch)
    pushneeded = needs_push(cwd, branch, upstream)

    try:
        diff_stat = run(["git", "diff", "--stat", f"{base}...HEAD"], cwd)
    except RuntimeError as e:
        diff_stat = ""
        errors.append(f"diff --stat failed: {e}")

    try:
        commit_log = run(["git", "log", "--oneline", f"{base}..HEAD"], cwd)
    except RuntimeError as e:
        commit_log = ""
        errors.append(f"git log failed: {e}")

    try:
        diff = run(["git", "diff", f"{base}...HEAD"], cwd)
    except RuntimeError as e:
        diff = ""
        errors.append(f"git diff failed: {e}")

    truncated = False
    if len(diff) > MAX_DIFF_CHARS:
        diff = diff[:MAX_DIFF_CHARS] + "\n... (diff truncated)\n"
        truncated = True

    pr_url = existing_pr_url(cwd, forge)

    return Preflight(
        branch=branch,
        base=base,
        has_commits_ahead=ahead > 0,
        commits_ahead=ahead,
        dirty=dirty,
        dirty_status=status,
        upstream=upstream,
        needs_push=pushneeded,
        existing_pr_url=pr_url,
        diff_stat=diff_stat,
        commit_log=commit_log,
        diff=diff,
        diff_truncated=truncated,
        errors=errors,
    )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--cwd", default=".")
    parser.add_argument("--forge", default="github")
    parser.add_argument("--base", default=None)
    args = parser.parse_args()

    try:
        base = resolve_base(args.cwd, current_branch(args.cwd), args.base)
        pre = collect(args.cwd, args.forge, base)
    except RuntimeError as e:
        print(json.dumps({"error": str(e)}))
        return 2

    print(json.dumps(asdict(pre), indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
