"""Push the current branch and open a PR/MR on the detected forge.

Dispatches to `gh` (GitHub), `glab` (GitLab), or `tea` (Gitea/Forgejo) based
on `--forge`. Title and body are supplied by the caller — Claude drafts them
using preflight output.

If a PR/MR already exists for the current branch, print its URL and return
success (no duplicate creation).
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from dataclasses import dataclass, asdict


@dataclass
class CreateResult:
    success: bool
    number: int | None
    url: str | None
    existed: bool
    error: str | None


def run(cmd: list[str], cwd: str | None = None, check: bool = False):
    return subprocess.run(
        cmd, cwd=cwd, capture_output=True, text=True, check=check
    )


def current_branch(cwd: str) -> str:
    r = run(["git", "rev-parse", "--abbrev-ref", "HEAD"], cwd, check=True)
    return r.stdout.strip()


def push_branch(cwd: str, branch: str) -> tuple[bool, str | None]:
    r = run(["git", "push", "--set-upstream", "origin", branch], cwd)
    if r.returncode != 0:
        msg = (r.stderr or r.stdout).strip()
        if "fetch first" in msg or "non-fast-forward" in msg:
            return False, "Remote branch has changes not present locally. Pull/rebase first."
        return False, f"git push failed: {msg}"
    return True, None


def create_github(
    cwd: str, title: str, body: str, base: str | None, draft: bool
) -> CreateResult:
    # Check for existing PR first
    existing = run(["gh", "pr", "view", "--json", "number,url"], cwd)
    if existing.returncode == 0 and existing.stdout.strip():
        try:
            data = json.loads(existing.stdout)
            return CreateResult(
                success=True,
                number=data.get("number"),
                url=data.get("url"),
                existed=True,
                error=None,
            )
        except json.JSONDecodeError:
            pass

    cmd = ["gh", "pr", "create", "--title", title, "--body", body or ""]
    if base:
        cmd += ["--base", base]
    if draft:
        cmd.append("--draft")
    r = run(cmd, cwd)
    if r.returncode != 0:
        # gh sometimes prints an existing URL on stderr when the PR exists
        m = re.search(
            r"(https://[^/]+/[^/]+/[^/]+/pull/\d+)", (r.stderr or "") + (r.stdout or "")
        )
        if m:
            url = m.group(1)
            num_m = re.search(r"/pull/(\d+)", url)
            return CreateResult(
                success=True,
                number=int(num_m.group(1)) if num_m else None,
                url=url,
                existed=True,
                error=None,
            )
        return CreateResult(
            success=False,
            number=None,
            url=None,
            existed=False,
            error=(r.stderr or r.stdout).strip()
            or "gh pr create failed with no output",
        )

    url = r.stdout.strip().splitlines()[-1] if r.stdout.strip() else ""
    m = re.search(r"/pull/(\d+)", url)
    return CreateResult(
        success=True,
        number=int(m.group(1)) if m else None,
        url=url or None,
        existed=False,
        error=None,
    )


def create_gitlab(
    cwd: str, title: str, body: str, base: str | None, draft: bool
) -> CreateResult:
    # Existing MR lookup
    existing = run(["glab", "mr", "view", "--output", "json"], cwd)
    if existing.returncode == 0 and existing.stdout.strip():
        try:
            data = json.loads(existing.stdout)
            return CreateResult(
                success=True,
                number=data.get("iid"),
                url=data.get("web_url"),
                existed=True,
                error=None,
            )
        except json.JSONDecodeError:
            pass

    final_title = f"Draft: {title}" if draft else title
    cmd = [
        "glab",
        "mr",
        "create",
        "--title",
        final_title,
        "--description",
        body or "",
        "--yes",
    ]
    if base:
        cmd += ["--target-branch", base]
    r = run(cmd, cwd)
    if r.returncode != 0:
        return CreateResult(
            success=False,
            number=None,
            url=None,
            existed=False,
            error=(r.stderr or r.stdout).strip() or "glab mr create failed",
        )
    out = (r.stdout or "") + "\n" + (r.stderr or "")
    m = re.search(r"(https?://\S+/-/merge_requests/(\d+))", out)
    if m:
        return CreateResult(
            success=True,
            number=int(m.group(2)),
            url=m.group(1),
            existed=False,
            error=None,
        )
    return CreateResult(
        success=True,
        number=None,
        url=None,
        existed=False,
        error=None,
    )


def create_gitea(
    cwd: str, title: str, body: str, base: str | None, draft: bool
) -> CreateResult:
    # `tea` does not expose a clean existing-PR lookup by branch; rely on the
    # creation step to surface a duplicate error and parse it.
    cmd = ["tea", "pr", "create", "--title", title, "--description", body or ""]
    if base:
        cmd += ["--target", base]
    if draft:
        # tea doesn't have a native --draft flag in all versions; prefix title.
        cmd[3] = f"WIP: {title}"
    r = run(cmd, cwd)
    if r.returncode != 0:
        msg = (r.stderr or r.stdout).strip()
        m = re.search(r"(https?://\S+/pulls/\d+)", msg)
        if m:
            url = m.group(1)
            num = re.search(r"/pulls/(\d+)", url)
            return CreateResult(
                success=True,
                number=int(num.group(1)) if num else None,
                url=url,
                existed=True,
                error=None,
            )
        return CreateResult(
            success=False,
            number=None,
            url=None,
            existed=False,
            error=msg or "tea pr create failed",
        )
    out = (r.stdout or "") + "\n" + (r.stderr or "")
    m = re.search(r"(https?://\S+/pulls/(\d+))", out)
    if m:
        return CreateResult(
            success=True,
            number=int(m.group(2)),
            url=m.group(1),
            existed=False,
            error=None,
        )
    return CreateResult(
        success=True,
        number=None,
        url=None,
        existed=False,
        error=None,
    )


CREATORS = {
    "github": create_github,
    "gitlab": create_gitlab,
    "gitea": create_gitea,
}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--cwd", default=".")
    parser.add_argument("--forge", required=True, choices=list(CREATORS))
    parser.add_argument("--title", required=True)
    parser.add_argument("--body", default="")
    parser.add_argument("--base", default=None)
    parser.add_argument("--draft", action="store_true")
    parser.add_argument(
        "--skip-push", action="store_true", help="Assume branch is already pushed"
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print the command that would run, but don't execute",
    )
    args = parser.parse_args()

    branch = current_branch(args.cwd)

    if args.dry_run:
        print(
            json.dumps(
                {
                    "dry_run": True,
                    "forge": args.forge,
                    "branch": branch,
                    "base": args.base,
                    "title": args.title,
                    "body_preview": (args.body or "")[:200],
                    "draft": args.draft,
                    "would_push": not args.skip_push,
                },
                indent=2,
            )
        )
        return 0

    if not args.skip_push:
        ok, err = push_branch(args.cwd, branch)
        if not ok:
            print(
                json.dumps(
                    asdict(
                        CreateResult(
                            success=False,
                            number=None,
                            url=None,
                            existed=False,
                            error=err,
                        )
                    ),
                    indent=2,
                )
            )
            return 1

    result = CREATORS[args.forge](
        args.cwd, args.title, args.body, args.base, args.draft
    )
    print(json.dumps(asdict(result), indent=2))
    return 0 if result.success else 1


if __name__ == "__main__":
    sys.exit(main())
