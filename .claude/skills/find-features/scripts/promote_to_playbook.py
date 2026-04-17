#!/usr/bin/env python3
"""Promote an approved feature into the dotfiles repo.

Claude authors a 'changeset' — a JSON document listing files to create,
append to, or replace under tools/<name>/. This script writes the files,
creates the directory if needed, and runs `git add` to stage the result.

The user still owns the commit. We never commit automatically.

Changeset format:
{
  "tool_name": "tmux-plugins",           // target dir under tools/
  "mode": "new" | "addon",               // purely informational; drives nothing
  "files": [
    {
      "path": "install_tmux-plugins.yml",   // relative to tools/<tool_name>/
      "content": "...full file content...",
      "write_mode": "create"                // create | replace | append
    },
    ...
  ]
}

Usage:
    python -m scripts.promote_to_playbook --changeset changeset.json
    cat changeset.json | python -m scripts.promote_to_playbook --changeset -
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from state import load_session, now_iso, repo_root, save_session  # noqa: E402


def write_file(target: Path, content: str, write_mode: str) -> str:
    target.parent.mkdir(parents=True, exist_ok=True)
    if write_mode == "create":
        if target.exists():
            raise RuntimeError(f"refusing to overwrite existing file: {target} "
                               f"(use write_mode=replace to force)")
        target.write_text(content)
        return "created"
    if write_mode == "replace":
        existed = target.exists()
        target.write_text(content)
        return "replaced" if existed else "created"
    if write_mode == "append":
        with target.open("a") as f:
            if content and not content.startswith("\n"):
                f.write("\n")
            f.write(content)
            if not content.endswith("\n"):
                f.write("\n")
        return "appended"
    raise ValueError(f"unknown write_mode: {write_mode!r}")


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--changeset", required=True,
                    help="path to changeset JSON, or '-' for stdin")
    ap.add_argument("--suggestion-id",
                    help="mark this suggestion approved in session state")
    ap.add_argument("--session-id", help="defaults to active session")
    ap.add_argument("--no-git-add", action="store_true",
                    help="skip running `git add` on the created/modified files")
    args = ap.parse_args(argv)

    if args.changeset == "-":
        cs = json.load(sys.stdin)
    else:
        with open(args.changeset) as f:
            cs = json.load(f)

    tool_name = cs["tool_name"]
    if "/" in tool_name or tool_name.startswith("."):
        raise ValueError(f"suspicious tool_name: {tool_name!r}")

    root = repo_root()
    tool_dir = root / "tools" / tool_name
    outcomes = []
    written_paths: list[Path] = []

    for f in cs["files"]:
        rel = f["path"]
        if rel.startswith("/") or ".." in Path(rel).parts:
            raise ValueError(f"suspicious file path: {rel!r}")
        target = tool_dir / rel
        result = write_file(target, f["content"], f.get("write_mode", "create"))
        outcomes.append({"path": str(target.relative_to(root)), "result": result})
        written_paths.append(target)

    if not args.no_git_add and written_paths:
        rels = [str(p.relative_to(root)) for p in written_paths]
        subprocess.run(["git", "add", "--", *rels], check=True, cwd=root)

    if args.suggestion_id:
        try:
            session = load_session(args.session_id)
        except FileNotFoundError:
            session = None
        if session:
            for trial in session["trials"]:
                if trial["suggestion_id"] == args.suggestion_id:
                    trial["status"] = "approved"
                    trial["approved_at"] = now_iso()
                    trial["promoted_tool_name"] = tool_name
            save_session(session)

    print(json.dumps({
        "tool_dir": str(tool_dir.relative_to(root)),
        "outcomes": outcomes,
        "staged": not args.no_git_add,
    }, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
