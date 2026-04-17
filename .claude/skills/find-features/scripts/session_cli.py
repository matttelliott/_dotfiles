#!/usr/bin/env python3
"""CLI for session lifecycle — start a session, record suggestions, pick which
ones to try, and inspect state.

Sessions are isolated by session_id. `new` writes a pointer at
state/active-session.json so other commands find the right session without
every call needing to pass --session-id. Explicit --session-id still works
when you need to operate on a non-active session.

Subcommands:
    new --intent "..."                       # start a fresh session (sets active)
    add-suggestions --file suggestions.json  # replace the suggestion list
    add-suggestions --file -                 # read from stdin
    select --ids sugg-1,sugg-3               # mark which to try (in this order)
    show                                     # pretty-print session state
    list                                     # list all sessions on disk
    clear                                    # delete all sessions + manifests (destructive)

Suggestion file format: a JSON array of objects, each with at minimum:
    {"id": "sugg-1", "type": "existing|addon|new", "title": "...",
     "rationale": "...", "tool": "tmux" }
"""

from __future__ import annotations

import argparse
import json
import shutil
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from state import (  # noqa: E402
    ACTIVE_POINTER,
    MANIFEST_DIR,
    SESSIONS_DIR,
    load_session,
    new_session,
    save_session,
)


def cmd_new(args: argparse.Namespace) -> int:
    data = new_session(args.intent)
    print(json.dumps({"session_id": data["session_id"]}, indent=2))
    return 0


def cmd_add_suggestions(args: argparse.Namespace) -> int:
    if args.file == "-":
        suggestions = json.load(sys.stdin)
    else:
        with open(args.file) as f:
            suggestions = json.load(f)
    if not isinstance(suggestions, list):
        print("suggestions file must contain a JSON array", file=sys.stderr)
        return 1
    seen_ids = set()
    for s in suggestions:
        sid = s.get("id")
        if not sid:
            print(f"suggestion missing id: {s!r}", file=sys.stderr)
            return 1
        if sid in seen_ids:
            print(f"duplicate suggestion id: {sid}", file=sys.stderr)
            return 1
        seen_ids.add(sid)
    session = load_session(args.session_id)
    session["suggestions"] = suggestions
    save_session(session)
    print(json.dumps({"count": len(suggestions),
                      "session_id": session["session_id"]}, indent=2))
    return 0


def cmd_select(args: argparse.Namespace) -> int:
    session = load_session(args.session_id)
    ids = [s.strip() for s in args.ids.split(",") if s.strip()]
    valid = {s["id"] for s in session["suggestions"]}
    unknown = [i for i in ids if i not in valid]
    if unknown:
        print(f"unknown suggestion ids: {unknown}", file=sys.stderr)
        return 1
    session["selected"] = ids
    save_session(session)
    print(json.dumps({"selected": ids,
                      "session_id": session["session_id"]}, indent=2))
    return 0


def cmd_show(args: argparse.Namespace) -> int:
    session = load_session(args.session_id)
    print(json.dumps(session, indent=2))
    return 0


def cmd_list(_: argparse.Namespace) -> int:
    if not SESSIONS_DIR.exists():
        print(json.dumps({"sessions": [], "active": None}, indent=2))
        return 0
    sessions = []
    for p in sorted(SESSIONS_DIR.glob("*.json")):
        try:
            with p.open() as f:
                s = json.load(f)
            sessions.append({"session_id": s["session_id"],
                             "intent": s.get("intent", ""),
                             "suggestions": len(s.get("suggestions", [])),
                             "trials": len(s.get("trials", []))})
        except (json.JSONDecodeError, KeyError):
            continue
    active = None
    if ACTIVE_POINTER.exists():
        with ACTIVE_POINTER.open() as f:
            active = json.load(f).get("session_id")
    print(json.dumps({"sessions": sessions, "active": active}, indent=2))
    return 0


def cmd_clear(args: argparse.Namespace) -> int:
    if not args.yes:
        print("refusing to clear without --yes (this deletes all sessions + manifests)",
              file=sys.stderr)
        return 1
    if ACTIVE_POINTER.exists():
        ACTIVE_POINTER.unlink()
    if SESSIONS_DIR.exists():
        shutil.rmtree(SESSIONS_DIR)
    if MANIFEST_DIR.exists():
        shutil.rmtree(MANIFEST_DIR)
    print("cleared")
    return 0


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    sub = ap.add_subparsers(dest="cmd", required=True)

    p = sub.add_parser("new")
    p.add_argument("--intent", required=True)
    p.set_defaults(fn=cmd_new)

    p = sub.add_parser("add-suggestions")
    p.add_argument("--file", required=True)
    p.add_argument("--session-id", help="defaults to active session")
    p.set_defaults(fn=cmd_add_suggestions)

    p = sub.add_parser("select")
    p.add_argument("--ids", required=True)
    p.add_argument("--session-id", help="defaults to active session")
    p.set_defaults(fn=cmd_select)

    p = sub.add_parser("show")
    p.add_argument("--session-id", help="defaults to active session")
    p.set_defaults(fn=cmd_show)

    p = sub.add_parser("list")
    p.set_defaults(fn=cmd_list)

    p = sub.add_parser("clear")
    p.add_argument("--yes", action="store_true")
    p.set_defaults(fn=cmd_clear)

    args = ap.parse_args(argv)
    return args.fn(args)


if __name__ == "__main__":
    raise SystemExit(main())
