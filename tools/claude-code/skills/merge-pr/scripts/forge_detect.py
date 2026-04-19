"""Detect which git forge the current repo's remote points at.

Supports GitHub, GitLab (incl. self-hosted), Gitea, and Forgejo. Emits JSON
for the skill's workflow to consume.

Detection rules:
- github.com → github (CLI: gh)
- gitlab.com or any host matching `gitlab.*` / `*.gitlab.*` → gitlab (CLI: glab)
- If the host appears in $MERGE_PR_GITEA_HOSTS (comma-separated) or
  $MERGE_PR_FORGEJO_HOSTS → gitea (CLI: tea)
- Override via $MERGE_PR_FORGE=github|gitlab|gitea (highest priority)
- Otherwise → unknown, and the user must set an override

The CLI chosen (gh / glab / tea) is reported with its availability so the
workflow can fail fast if the tool isn't installed.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
from dataclasses import dataclass, asdict


FORGE_CLIS = {
    "github": "gh",
    "gitlab": "glab",
    "gitea": "tea",
}


@dataclass
class ForgeInfo:
    forge: str  # github | gitlab | gitea | unknown
    host: str
    owner: str
    repo: str
    remote_url: str
    cli: str | None
    cli_installed: bool
    cli_path: str | None
    override: bool  # True if $MERGE_PR_FORGE was used


def run(cmd: list[str], cwd: str | None = None) -> str:
    result = subprocess.run(
        cmd, cwd=cwd, capture_output=True, text=True, check=False
    )
    if result.returncode != 0:
        raise RuntimeError(
            f"{' '.join(cmd)} failed ({result.returncode}): {result.stderr.strip()}"
        )
    return result.stdout.strip()


def get_remote_url(cwd: str | None, remote: str) -> str:
    return run(["git", "remote", "get-url", remote], cwd=cwd)


def parse_remote_url(url: str) -> tuple[str, str, str]:
    """Return (host, owner, repo) for https/ssh/git remotes.

    Raises ValueError if the URL is not parseable as a typical forge remote.
    """
    url = url.strip()
    m = re.match(r"^(?:ssh://)?(?:[^@]+@)?([^:/]+)[:/](.+?)(?:\.git)?/?$", url)
    if m and "@" in url.split("://", 1)[-1] and ":" in url.split("@", 1)[-1]:
        host = m.group(1)
        path = m.group(2)
    else:
        m = re.match(
            r"^(?:https?|git|ssh)://(?:[^@/]+@)?([^:/]+)(?::\d+)?/(.+?)(?:\.git)?/?$",
            url,
        )
        if not m:
            raise ValueError(f"Could not parse remote URL: {url!r}")
        host = m.group(1)
        path = m.group(2)
    parts = path.split("/")
    if len(parts) < 2:
        raise ValueError(f"Remote URL missing owner/repo: {url!r}")
    owner = "/".join(parts[:-1])
    repo = parts[-1]
    return host, owner, repo


def detect_forge_from_host(host: str) -> str:
    override = os.environ.get("MERGE_PR_FORGE", "").strip().lower()
    if override in FORGE_CLIS:
        return override
    host_l = host.lower()
    if host_l == "github.com" or host_l.endswith(".github.com"):
        return "github"
    if host_l == "gitlab.com" or "gitlab" in host_l:
        return "gitlab"
    gitea_hosts = _split_env("MERGE_PR_GITEA_HOSTS")
    forgejo_hosts = _split_env("MERGE_PR_FORGEJO_HOSTS")
    if host_l in gitea_hosts or host_l in forgejo_hosts:
        return "gitea"
    if "gitea" in host_l or "forgejo" in host_l or "codeberg" in host_l:
        return "gitea"
    return "unknown"


def _split_env(name: str) -> set[str]:
    raw = os.environ.get(name, "")
    return {h.strip().lower() for h in raw.split(",") if h.strip()}


def detect(cwd: str | None, remote: str) -> ForgeInfo:
    url = get_remote_url(cwd, remote)
    host, owner, repo = parse_remote_url(url)
    forge = detect_forge_from_host(host)
    cli = FORGE_CLIS.get(forge)
    cli_path = shutil.which(cli) if cli else None
    return ForgeInfo(
        forge=forge,
        host=host,
        owner=owner,
        repo=repo,
        remote_url=url,
        cli=cli,
        cli_installed=cli_path is not None,
        cli_path=cli_path,
        override=bool(os.environ.get("MERGE_PR_FORGE")),
    )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--cwd", default=None)
    parser.add_argument("--remote", default="origin")
    parser.add_argument(
        "--parse-url", help="Parse a URL directly instead of reading git remote"
    )
    args = parser.parse_args()

    try:
        if args.parse_url:
            host, owner, repo = parse_remote_url(args.parse_url)
            forge = detect_forge_from_host(host)
            cli = FORGE_CLIS.get(forge)
            cli_path = shutil.which(cli) if cli else None
            info = ForgeInfo(
                forge=forge,
                host=host,
                owner=owner,
                repo=repo,
                remote_url=args.parse_url,
                cli=cli,
                cli_installed=cli_path is not None,
                cli_path=cli_path,
                override=bool(os.environ.get("MERGE_PR_FORGE")),
            )
        else:
            info = detect(args.cwd, args.remote)
    except (RuntimeError, ValueError) as e:
        print(json.dumps({"error": str(e)}))
        return 2

    print(json.dumps(asdict(info), indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
