#!/usr/bin/env python3
"""Reverse an install by reading its manifest.

Reads the manifest written by install_feature.py and undoes each entry in
reverse order. We try to be safe: if something looks ambiguous (e.g. a dir
that predated the install), we leave it alone and report it rather than
deleting the user's existing state.

Usage:
    python -m scripts.uninstall_feature --suggestion-id sugg-1
    python -m scripts.uninstall_feature --manifest path/to/manifest.json
"""

from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from state import (  # noqa: E402
    detect_os,
    load_manifest,
    load_session,
    manifest_path,
    now_iso,
    save_manifest,
    save_session,
)


def reverse_entry(entry: dict, os_family: str) -> dict:
    """Reverse one manifest entry. Return an outcome record."""
    if entry.get("skipped"):
        return {"entry": entry, "result": "no-op (was skipped)"}

    atype = entry["type"]
    action = entry.get("action", {})

    if atype == "brew":
        pkg = entry.get("installed_package") or action.get("package")
        if os_family == "darwin" and pkg:
            subprocess.run(["brew", "uninstall", pkg], check=False)
            return {"entry": entry, "result": f"brew uninstall {pkg}"}
        return {"entry": entry, "result": "skipped (wrong os or no package)"}

    if atype == "apt":
        pkg = entry.get("installed_package") or action.get("package")
        if os_family == "debian" and pkg:
            subprocess.run(["sudo", "apt-get", "remove", "-y", pkg], check=False)
            return {"entry": entry, "result": f"apt remove {pkg}"}
        return {"entry": entry, "result": "skipped (wrong os or no package)"}

    if atype == "pacman":
        pkg = entry.get("installed_package") or action.get("package")
        if os_family == "arch" and pkg:
            subprocess.run(["sudo", "pacman", "-R", "--noconfirm", pkg], check=False)
            return {"entry": entry, "result": f"pacman -R {pkg}"}
        return {"entry": entry, "result": "skipped (wrong os or no package)"}

    if atype == "cmd":
        reverse = entry.get("reverse_cmd") or action.get("reverse_cmd")
        if reverse:
            subprocess.run(reverse, shell=True, check=False)
            return {"entry": entry, "result": f"ran reverse_cmd"}
        return {"entry": entry, "result": "no reverse_cmd — manual cleanup needed"}

    if atype == "git_clone":
        dest = entry.get("cloned_to") or action.get("dest")
        if dest and Path(dest).exists():
            shutil.rmtree(dest)
            return {"entry": entry, "result": f"removed {dest}"}
        return {"entry": entry, "result": f"path missing — nothing to remove"}

    if atype == "mkdir":
        p = Path(entry["path"])
        if entry.get("preexisting"):
            return {"entry": entry, "result": "dir predated install — leaving"}
        try:
            p.rmdir()  # only removes if empty
            return {"entry": entry, "result": f"removed {p}"}
        except OSError as e:
            return {"entry": entry, "result": f"dir not empty, leaving: {e}"}

    if atype == "file_create":
        p = Path(entry["path"])
        if p.exists():
            p.unlink()
            return {"entry": entry, "result": f"deleted {p}"}
        return {"entry": entry, "result": "file already gone"}

    if atype == "file_append":
        p = Path(entry["path"])
        appended = entry["appended"]
        if not p.exists():
            if not entry.get("preexisting"):
                return {"entry": entry, "result": "file gone (and we created it) — ok"}
            return {"entry": entry, "result": "file gone but it predated install — suspicious"}
        text = p.read_text()
        if appended in text:
            new_text = text.replace(appended, "", 1)
            if new_text.strip() == "" and not entry.get("preexisting"):
                p.unlink()
                return {"entry": entry, "result": f"appended chunk removed, file emptied & deleted"}
            p.write_text(new_text)
            return {"entry": entry, "result": f"appended chunk removed from {p}"}
        return {"entry": entry, "result": "appended chunk not found — manual cleanup needed"}

    return {"entry": entry, "result": f"unknown action type {atype!r}"}


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--suggestion-id", help="look up manifest from active session")
    ap.add_argument("--manifest", help="explicit manifest path")
    ap.add_argument("--session-id", help="defaults to active session")
    args = ap.parse_args(argv)

    if args.manifest:
        mpath = Path(args.manifest)
    elif args.suggestion_id:
        session = load_session(args.session_id)
        mpath = manifest_path(session["session_id"], args.suggestion_id)
    else:
        ap.error("provide --suggestion-id or --manifest")

    if not mpath.exists():
        print(f"no manifest at {mpath}", file=sys.stderr)
        return 1

    manifest = load_manifest(mpath)
    os_family = detect_os()
    outcomes = []
    # Reverse order: undo in the opposite sequence from install.
    for entry in reversed(manifest["entries"]):
        outcome = reverse_entry(entry, os_family)
        outcomes.append(outcome)

    manifest["status"] = "uninstalled"
    manifest["uninstalled_at"] = now_iso()
    manifest["uninstall_outcomes"] = outcomes
    save_manifest(mpath, manifest)

    # Update session trial status if we have a session.
    try:
        session = load_session(args.session_id)
    except FileNotFoundError:
        session = None
    if session and args.suggestion_id:
        for trial in session["trials"]:
            if trial["suggestion_id"] == args.suggestion_id:
                trial["status"] = "rejected"
                trial["uninstalled_at"] = manifest["uninstalled_at"]
        save_session(session)

    print(json.dumps({"manifest": str(mpath), "outcomes": outcomes}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
