#!/usr/bin/env python3
"""Execute a Claude-authored install plan, recording a reversible manifest.

The plan is a JSON document with an `actions` array. Each action has a type
and type-specific fields. Supported types:

  {"type": "brew",   "package": "lazygit"}
  {"type": "apt",    "package": "lazygit"}
  {"type": "pacman", "package": "lazygit"}
  {"type": "cmd",    "cmd": "foo --install", "reverse_cmd": "foo --uninstall"}
  {"type": "git_clone", "url": "https://...", "dest": "~/.tmux/plugins/tpm"}
  {"type": "mkdir", "path": "~/.config/foo"}
  {"type": "file_create", "path": "~/.config/foo/conf", "content": "..."}
  {"type": "file_append", "path": "~/.zshrc", "content": "source ~/.config/foo"}

For each executed action we write an entry to the manifest capturing the
before-state so uninstall_feature.py can reverse it. We run actions in order,
stop on the first failure, and write the manifest regardless — a partial
install still needs a partial uninstall.

Usage:
    python -m scripts.install_feature --suggestion-id sugg-1 --plan plan.json
    cat plan.json | python -m scripts.install_feature --suggestion-id sugg-1 --plan -
"""

from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Any

sys.path.insert(0, str(Path(__file__).resolve().parent))
from state import (  # noqa: E402
    detect_os,
    load_session,
    manifest_path,
    now_iso,
    save_manifest,
    save_session,
)


def expand(path: str) -> Path:
    return Path(os.path.expandvars(os.path.expanduser(path)))


def run_action(action: dict, os_family: str) -> dict:
    """Execute one action. Return a manifest entry capturing what was done.

    Raises on failure. The manifest entry records enough to reverse the action.
    """
    atype = action["type"]
    record: dict[str, Any] = {"type": atype, "action": action}

    if atype == "brew":
        if os_family != "darwin":
            record["skipped"] = f"os={os_family}, brew is darwin-only"
            return record
        pkg = action["package"]
        subprocess.run(["brew", "install", pkg], check=True)
        record["installed_package"] = pkg
        return record

    if atype == "apt":
        if os_family != "debian":
            record["skipped"] = f"os={os_family}, apt is debian-only"
            return record
        pkg = action["package"]
        subprocess.run(["sudo", "apt-get", "install", "-y", pkg], check=True)
        record["installed_package"] = pkg
        return record

    if atype == "pacman":
        if os_family != "arch":
            record["skipped"] = f"os={os_family}, pacman is arch-only"
            return record
        pkg = action["package"]
        subprocess.run(["sudo", "pacman", "-S", "--noconfirm", pkg], check=True)
        record["installed_package"] = pkg
        return record

    if atype == "cmd":
        subprocess.run(action["cmd"], shell=True, check=True)
        # reverse_cmd is stored as-is so uninstall can re-run it.
        if "reverse_cmd" in action:
            record["reverse_cmd"] = action["reverse_cmd"]
        return record

    if atype == "git_clone":
        dest = expand(action["dest"])
        if dest.exists():
            record["skipped"] = f"dest already exists: {dest}"
            return record
        subprocess.run(["git", "clone", action["url"], str(dest)], check=True)
        record["cloned_to"] = str(dest)
        return record

    if atype == "mkdir":
        p = expand(action["path"])
        existed = p.exists()
        p.mkdir(parents=True, exist_ok=True)
        record["path"] = str(p)
        record["preexisting"] = existed
        return record

    if atype == "file_create":
        p = expand(action["path"])
        if p.exists():
            # Don't clobber silently. Claude should use file_append or an
            # explicit overwrite flag if that's the intent.
            raise RuntimeError(f"file already exists: {p} (refusing to overwrite)")
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(action["content"])
        record["path"] = str(p)
        return record

    if atype == "file_append":
        p = expand(action["path"])
        existed = p.exists()
        content = action["content"]
        if not content.endswith("\n"):
            content = content + "\n"
        with p.open("a") as f:
            f.write(content)
        record["path"] = str(p)
        record["appended"] = content
        record["preexisting"] = existed
        return record

    raise ValueError(f"unknown action type: {atype!r}")


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--suggestion-id", required=True)
    ap.add_argument("--plan", required=True,
                    help="path to plan JSON file, or '-' for stdin")
    ap.add_argument("--session-id", help="defaults to active session")
    args = ap.parse_args(argv)

    if args.plan == "-":
        plan = json.load(sys.stdin)
    else:
        with open(args.plan) as f:
            plan = json.load(f)
    actions = plan["actions"]

    session = load_session(args.session_id)
    os_family = detect_os()
    mpath = manifest_path(session["session_id"], args.suggestion_id)

    manifest = {
        "suggestion_id": args.suggestion_id,
        "session_id": session["session_id"],
        "os_family": os_family,
        "started_at": now_iso(),
        "entries": [],
        "status": "in_progress",
    }

    try:
        for action in actions:
            entry = run_action(action, os_family)
            manifest["entries"].append(entry)
            save_manifest(mpath, manifest)  # checkpoint after each step
        manifest["status"] = "installed"
        manifest["finished_at"] = now_iso()
    except Exception as e:
        manifest["status"] = "failed"
        manifest["error"] = str(e)
        manifest["finished_at"] = now_iso()
        save_manifest(mpath, manifest)
        print(f"install failed: {e}", file=sys.stderr)
        print(str(mpath))
        return 1

    save_manifest(mpath, manifest)

    trial = {
        "suggestion_id": args.suggestion_id,
        "manifest_path": str(mpath),
        "status": "installed",
        "installed_at": manifest["finished_at"],
    }
    # Replace any existing trial entry for this suggestion.
    session["trials"] = [t for t in session["trials"]
                         if t["suggestion_id"] != args.suggestion_id] + [trial]
    save_session(session)

    print(str(mpath))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
