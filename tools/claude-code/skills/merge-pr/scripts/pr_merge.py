"""Merge the PR/MR associated with the current branch on the detected forge.

Dispatches to `gh` (GitHub), `glab` (GitLab), or `tea` (Gitea/Forgejo). The
caller chooses the merge method (squash/merge/rebase) and whether to delete
the source branch.

Assumes `pr_status.py` was already run and confirmed an open PR exists. The
merge CLIs will surface their own errors (conflicts, failing required checks,
missing approvals, etc.) if the PR isn't actually ready.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from dataclasses import dataclass, asdict


METHODS = ("squash", "merge", "rebase")


@dataclass
class MergeResult:
    success: bool
    method: str
    url: str | None
    already_merged: bool
    error: str | None


def run(cmd: list[str], cwd: str | None = None):
    return subprocess.run(cmd, cwd=cwd, capture_output=True, text=True)


def _in_linked_worktree(cwd: str) -> bool:
    """True when cwd is a linked worktree (not the main one).

    In linked worktrees the base branch is typically checked out elsewhere,
    so CLIs that try to `git checkout <base>` as part of branch cleanup
    will fail.
    """
    r1 = run(["git", "rev-parse", "--git-dir"], cwd)
    r2 = run(["git", "rev-parse", "--git-common-dir"], cwd)
    if r1.returncode != 0 or r2.returncode != 0:
        return False
    git_dir = os.path.realpath(os.path.join(cwd, r1.stdout.strip()))
    common_dir = os.path.realpath(os.path.join(cwd, r2.stdout.strip()))
    return git_dir != common_dir


def _delete_remote_branch(cwd: str) -> tuple[bool, str]:
    branch_r = run(["git", "rev-parse", "--abbrev-ref", "HEAD"], cwd)
    branch = branch_r.stdout.strip()
    if not branch or branch == "HEAD":
        return False, "could not resolve current branch name"
    r = run(["git", "push", "origin", "--delete", branch], cwd)
    if r.returncode != 0:
        return False, ((r.stderr or r.stdout) or "git push --delete failed").strip()
    return True, ""


def merge_github(
    cwd: str, method: str, delete_branch: bool, auto: bool, admin: bool
) -> MergeResult:
    # `gh pr merge --delete-branch` performs a local checkout of the base
    # branch so it can delete the feature branch locally. In a linked
    # worktree the base is held by another worktree and the checkout fails
    # — even though the server-side merge has already completed. Split the
    # request into a plain merge + explicit remote-branch delete.
    skip_local_delete = delete_branch and _in_linked_worktree(cwd)

    cmd = ["gh", "pr", "merge", f"--{method}"]
    if delete_branch and not skip_local_delete:
        cmd.append("--delete-branch")
    if auto:
        cmd.append("--auto")
    if admin:
        cmd.append("--admin")
    r = run(cmd, cwd)
    out = (r.stdout or "") + "\n" + (r.stderr or "")
    if r.returncode != 0:
        if "already been merged" in out.lower() or "pull request is already merged" in out.lower():
            return MergeResult(success=True, method=method, url=None, already_merged=True, error=None)
        return MergeResult(
            success=False,
            method=method,
            url=None,
            already_merged=False,
            error=out.strip() or "gh pr merge failed",
        )

    if skip_local_delete and not auto:
        ok, err = _delete_remote_branch(cwd)
        if not ok:
            return MergeResult(
                success=False,
                method=method,
                url=None,
                already_merged=False,
                error=f"merge succeeded but remote branch delete failed: {err}",
            )

    m = re.search(r"(https://[^/]+/[^/]+/[^/]+/pull/\d+)", out)
    return MergeResult(
        success=True,
        method=method,
        url=m.group(1) if m else None,
        already_merged=False,
        error=None,
    )


def merge_gitlab(
    cwd: str, method: str, delete_branch: bool, auto: bool, admin: bool
) -> MergeResult:
    cmd = ["glab", "mr", "merge", "--yes"]
    if method == "squash":
        cmd.append("--squash")
    elif method == "rebase":
        cmd.append("--rebase")
    # method == "merge" uses glab's default merge-commit behavior
    if delete_branch:
        cmd.append("--remove-source-branch")
    if auto:
        cmd.append("--when-pipeline-succeeds")
    r = run(cmd, cwd)
    out = (r.stdout or "") + "\n" + (r.stderr or "")
    if r.returncode != 0:
        if "already merged" in out.lower():
            return MergeResult(success=True, method=method, url=None, already_merged=True, error=None)
        return MergeResult(
            success=False,
            method=method,
            url=None,
            already_merged=False,
            error=out.strip() or "glab mr merge failed",
        )
    m = re.search(r"(https?://\S+/-/merge_requests/\d+)", out)
    return MergeResult(
        success=True,
        method=method,
        url=m.group(1) if m else None,
        already_merged=False,
        error=None,
    )


def merge_gitea(
    cwd: str, method: str, delete_branch: bool, auto: bool, admin: bool
) -> MergeResult:
    branch_r = run(["git", "rev-parse", "--abbrev-ref", "HEAD"], cwd)
    branch = branch_r.stdout.strip()
    # `tea pr list` omits head/base from its default fields — ask explicitly.
    lst = run(
        [
            "tea", "pr", "list",
            "--output", "json",
            "--state", "open",
            "--fields", "index,title,state,head,base,url,mergeable",
        ],
        cwd,
    )
    if lst.returncode != 0:
        return MergeResult(
            success=False,
            method=method,
            url=None,
            already_merged=False,
            error=(lst.stderr or lst.stdout).strip() or "tea pr list failed",
        )
    try:
        prs = json.loads(lst.stdout)
    except json.JSONDecodeError:
        return MergeResult(
            success=False,
            method=method,
            url=None,
            already_merged=False,
            error="could not parse tea pr list output",
        )

    pr_num = None
    pr_url = None
    for pr in prs:
        head = pr.get("head") or pr.get("head_branch") or (pr.get("head_ref") or {})
        if isinstance(head, dict):
            head = head.get("ref")
        if head == branch:
            pr_num = pr.get("index") or pr.get("number")
            pr_url = pr.get("html_url") or pr.get("url")
            break
    if not pr_num:
        return MergeResult(
            success=False,
            method=method,
            url=None,
            already_merged=False,
            error=f"no open PR found for branch {branch}",
        )

    # tea 0.14.x has no --delete flag on `pr merge`; delete the branch
    # ourselves after a successful merge.
    cmd = ["tea", "pr", "merge", "--style", method, str(pr_num)]
    r = run(cmd, cwd)
    out = (r.stdout or "") + "\n" + (r.stderr or "")
    if r.returncode != 0:
        if "already merged" in out.lower():
            return MergeResult(success=True, method=method, url=pr_url, already_merged=True, error=None)
        return MergeResult(
            success=False,
            method=method,
            url=pr_url,
            already_merged=False,
            error=out.strip() or "tea pr merge failed",
        )

    if delete_branch:
        ok, err = _delete_remote_branch(cwd)
        if not ok:
            return MergeResult(
                success=False,
                method=method,
                url=pr_url,
                already_merged=False,
                error=f"merge succeeded but remote branch delete failed: {err}",
            )

    return MergeResult(
        success=True,
        method=method,
        url=pr_url,
        already_merged=False,
        error=None,
    )


MERGERS = {
    "github": merge_github,
    "gitlab": merge_gitlab,
    "gitea": merge_gitea,
}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--cwd", default=".")
    parser.add_argument("--forge", required=True, choices=list(MERGERS))
    parser.add_argument(
        "--method",
        default="squash",
        choices=METHODS,
        help="Merge method (default: squash). Override via $MERGE_PR_METHOD.",
    )
    parser.add_argument(
        "--delete-branch",
        action="store_true",
        help="Delete source branch after merge",
    )
    parser.add_argument(
        "--auto",
        action="store_true",
        help="Enable auto-merge (merge when checks pass). GitHub/GitLab only.",
    )
    parser.add_argument(
        "--admin",
        action="store_true",
        help="GitHub only: bypass branch protections (requires admin).",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print the command that would run, but don't execute",
    )
    args = parser.parse_args()

    if args.dry_run:
        print(
            json.dumps(
                {
                    "dry_run": True,
                    "forge": args.forge,
                    "method": args.method,
                    "delete_branch": args.delete_branch,
                    "auto": args.auto,
                    "admin": args.admin,
                },
                indent=2,
            )
        )
        return 0

    result = MERGERS[args.forge](
        args.cwd, args.method, args.delete_branch, args.auto, args.admin
    )
    print(json.dumps(asdict(result), indent=2))
    return 0 if result.success else 1


if __name__ == "__main__":
    sys.exit(main())
