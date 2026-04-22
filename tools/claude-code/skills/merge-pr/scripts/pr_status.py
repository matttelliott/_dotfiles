"""Check whether a PR/MR exists for the current branch and report its state.

Outputs JSON describing the PR (number, url, state, checks, reviews, mergeable
status). The skill uses this to decide whether to proceed with a merge, warn
about blockers, or bail because no PR exists.

Supports GitHub (`gh`), GitLab (`glab`), and Gitea/Forgejo (`tea`).
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from dataclasses import dataclass, asdict, field
from typing import Any


@dataclass
class PRStatus:
    exists: bool
    number: int | None = None
    url: str | None = None
    title: str | None = None
    state: str | None = None           # open | closed | merged
    is_draft: bool | None = None
    mergeable: str | None = None       # MERGEABLE | CONFLICTING | UNKNOWN (normalized)
    merge_state: str | None = None     # forge-specific extra detail (e.g. BLOCKED, CLEAN)
    checks: str | None = None          # summary: none|passing|failing|pending
    checks_detail: dict[str, int] = field(default_factory=dict)
    review_decision: str | None = None  # APPROVED | CHANGES_REQUESTED | REVIEW_REQUIRED | None
    head_branch: str | None = None
    base_branch: str | None = None
    error: str | None = None


def run(cmd: list[str], cwd: str | None = None):
    return subprocess.run(cmd, cwd=cwd, capture_output=True, text=True)


def current_branch(cwd: str) -> str:
    r = run(["git", "rev-parse", "--abbrev-ref", "HEAD"], cwd)
    return r.stdout.strip()


def summarize_checks_github(rollup: list[dict[str, Any]]) -> tuple[str, dict[str, int]]:
    if not rollup:
        return "none", {"total": 0}
    total = len(rollup)
    passing = 0
    failing = 0
    pending = 0
    for c in rollup:
        conclusion = (c.get("conclusion") or "").upper()
        status = (c.get("status") or c.get("state") or "").upper()
        if conclusion in ("SUCCESS", "NEUTRAL", "SKIPPED"):
            passing += 1
        elif conclusion in ("FAILURE", "CANCELLED", "TIMED_OUT", "ACTION_REQUIRED", "STALE"):
            failing += 1
        elif status in ("IN_PROGRESS", "QUEUED", "PENDING", "WAITING") or conclusion == "":
            pending += 1
        else:
            pending += 1
    detail = {"total": total, "passing": passing, "failing": failing, "pending": pending}
    if failing:
        return "failing", detail
    if pending:
        return "pending", detail
    return "passing", detail


def status_github(cwd: str) -> PRStatus:
    r = run(
        [
            "gh",
            "pr",
            "view",
            "--json",
            "number,url,title,state,isDraft,mergeable,mergeStateStatus,"
            "statusCheckRollup,reviewDecision,headRefName,baseRefName",
        ],
        cwd,
    )
    if r.returncode != 0:
        msg = (r.stderr or r.stdout).lower()
        if "no pull requests found" in msg or "no open pull requests" in msg:
            return PRStatus(exists=False)
        return PRStatus(exists=False, error=(r.stderr or r.stdout).strip())
    try:
        data = json.loads(r.stdout)
    except json.JSONDecodeError:
        return PRStatus(exists=False, error="could not parse gh output")

    checks_summary, checks_detail = summarize_checks_github(
        data.get("statusCheckRollup") or []
    )
    state = (data.get("state") or "").lower() or None
    mergeable_raw = (data.get("mergeable") or "").upper() or None
    return PRStatus(
        exists=True,
        number=data.get("number"),
        url=data.get("url"),
        title=data.get("title"),
        state=state,
        is_draft=data.get("isDraft"),
        mergeable=mergeable_raw,
        merge_state=data.get("mergeStateStatus"),
        checks=checks_summary,
        checks_detail=checks_detail,
        review_decision=data.get("reviewDecision") or None,
        head_branch=data.get("headRefName"),
        base_branch=data.get("baseRefName"),
    )


def status_gitlab(cwd: str) -> PRStatus:
    r = run(["glab", "mr", "view", "--output", "json"], cwd)
    if r.returncode != 0:
        msg = (r.stderr or r.stdout).lower()
        if "no open merge request" in msg or "not found" in msg:
            return PRStatus(exists=False)
        return PRStatus(exists=False, error=(r.stderr or r.stdout).strip())
    try:
        data = json.loads(r.stdout)
    except json.JSONDecodeError:
        return PRStatus(exists=False, error="could not parse glab output")

    pipeline = data.get("head_pipeline") or data.get("pipeline") or {}
    pstatus = (pipeline.get("status") or "").lower()
    if not pstatus:
        checks = "none"
    elif pstatus in ("success", "manual", "skipped"):
        checks = "passing"
    elif pstatus in ("failed", "canceled"):
        checks = "failing"
    else:
        checks = "pending"

    merge_status = (data.get("detailed_merge_status") or data.get("merge_status") or "").lower()
    if merge_status in ("mergeable", "can_be_merged"):
        mergeable = "MERGEABLE"
    elif "conflict" in merge_status or merge_status == "cannot_be_merged":
        mergeable = "CONFLICTING"
    else:
        mergeable = "UNKNOWN"

    state_raw = (data.get("state") or "").lower() or None

    approvals = data.get("approvals_before_merge")
    review_decision = None
    if approvals is not None:
        review_decision = "APPROVED" if (data.get("upvotes") or 0) >= approvals else "REVIEW_REQUIRED"

    return PRStatus(
        exists=True,
        number=data.get("iid"),
        url=data.get("web_url"),
        title=data.get("title"),
        state=state_raw,
        is_draft=data.get("draft") or data.get("work_in_progress"),
        mergeable=mergeable,
        merge_state=merge_status or None,
        checks=checks,
        checks_detail={"pipeline_status": pstatus} if pstatus else {},
        review_decision=review_decision,
        head_branch=data.get("source_branch"),
        base_branch=data.get("target_branch"),
    )


def status_gitea(cwd: str) -> PRStatus:
    branch = current_branch(cwd)
    # `tea pr list` omits head/base/url from its default fields — ask explicitly.
    r = run(
        [
            "tea", "pr", "list",
            "--output", "json",
            "--state", "open",
            "--fields", "index,title,state,head,base,url,mergeable",
        ],
        cwd,
    )
    if r.returncode != 0:
        return PRStatus(exists=False, error=(r.stderr or r.stdout).strip())
    try:
        prs = json.loads(r.stdout)
    except json.JSONDecodeError:
        return PRStatus(exists=False, error="could not parse tea output")

    match = None
    for pr in prs:
        head = pr.get("head") or pr.get("head_branch") or (pr.get("head_ref") or {})
        if isinstance(head, dict):
            head = head.get("ref")
        if head == branch:
            match = pr
            break
    if not match:
        return PRStatus(exists=False)

    mergeable_raw = match.get("mergeable")
    if mergeable_raw is True:
        mergeable = "MERGEABLE"
    elif mergeable_raw is False:
        mergeable = "CONFLICTING"
    else:
        mergeable = "UNKNOWN"

    base = match.get("base") or {}
    if isinstance(base, dict):
        base = base.get("ref")

    return PRStatus(
        exists=True,
        number=match.get("index") or match.get("number"),
        url=match.get("html_url") or match.get("url"),
        title=match.get("title"),
        state=(match.get("state") or "").lower() or None,
        is_draft=match.get("draft"),
        mergeable=mergeable,
        merge_state=None,
        checks="none",
        checks_detail={},
        review_decision=None,
        head_branch=branch,
        base_branch=base,
    )


STATUS_FNS = {
    "github": status_github,
    "gitlab": status_gitlab,
    "gitea": status_gitea,
}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--cwd", default=".")
    parser.add_argument("--forge", required=True, choices=list(STATUS_FNS))
    args = parser.parse_args()

    result = STATUS_FNS[args.forge](args.cwd)
    print(json.dumps(asdict(result), indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
