"""Post a comment on the PR/MR for the current branch.

Dispatches to `gh pr comment` (GitHub), `glab mr note` (GitLab), or `tea`
(Gitea/Forgejo). Gitea's `tea` CLI doesn't expose a branch-based comment
command in older versions — the script probes and reports `supported=False`
so callers can silently skip instead of treating it as an error.
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from dataclasses import dataclass, asdict


@dataclass
class CommentResult:
    success: bool
    supported: bool
    error: str | None


def run(cmd: list[str], cwd: str | None = None):
    return subprocess.run(cmd, cwd=cwd, capture_output=True, text=True)


def comment_github(cwd: str, body: str) -> CommentResult:
    r = run(["gh", "pr", "comment", "--body", body], cwd)
    if r.returncode != 0:
        return CommentResult(
            success=False,
            supported=True,
            error=(r.stderr or r.stdout).strip() or "gh pr comment failed",
        )
    return CommentResult(success=True, supported=True, error=None)


def comment_gitlab(cwd: str, body: str) -> CommentResult:
    r = run(["glab", "mr", "note", "--message", body], cwd)
    if r.returncode != 0:
        return CommentResult(
            success=False,
            supported=True,
            error=(r.stderr or r.stdout).strip() or "glab mr note failed",
        )
    return CommentResult(success=True, supported=True, error=None)


def comment_gitea(cwd: str, body: str) -> CommentResult:
    # tea's comment subcommand takes a PR index and a body, but not every
    # version ships it. Probe --help; bail out as unsupported if missing.
    probe = run(["tea", "comment", "--help"])
    if probe.returncode != 0:
        return CommentResult(
            success=False,
            supported=False,
            error="tea CLI does not support comments in this version",
        )

    branch = run(["git", "rev-parse", "--abbrev-ref", "HEAD"], cwd).stdout.strip()
    lst = run(["tea", "pr", "list", "--output", "json"], cwd)
    if lst.returncode != 0:
        return CommentResult(
            success=False,
            supported=True,
            error=(lst.stderr or lst.stdout).strip() or "tea pr list failed",
        )
    try:
        data = json.loads(lst.stdout)
    except json.JSONDecodeError:
        return CommentResult(
            success=False, supported=True, error="could not parse tea pr list output"
        )

    pr_num = None
    for item in data:
        head = item.get("head") or item.get("head_branch")
        if head == branch:
            pr_num = item.get("index") or item.get("number")
            break
    if not pr_num:
        return CommentResult(
            success=False,
            supported=True,
            error=f"no open PR found for branch {branch}",
        )

    r = run(["tea", "comment", str(pr_num), body], cwd)
    if r.returncode != 0:
        return CommentResult(
            success=False,
            supported=True,
            error=(r.stderr or r.stdout).strip() or "tea comment failed",
        )
    return CommentResult(success=True, supported=True, error=None)


COMMENTERS = {
    "github": comment_github,
    "gitlab": comment_gitlab,
    "gitea": comment_gitea,
}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--cwd", default=".")
    parser.add_argument("--forge", required=True, choices=list(COMMENTERS))
    parser.add_argument("--body", required=True)
    args = parser.parse_args()

    result = COMMENTERS[args.forge](args.cwd, args.body)
    print(json.dumps(asdict(result), indent=2))
    # Unsupported is not a failure — callers can skip silently.
    if not result.supported:
        return 0
    return 0 if result.success else 1


if __name__ == "__main__":
    sys.exit(main())
