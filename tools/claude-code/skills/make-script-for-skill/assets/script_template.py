#!/usr/bin/env python3
"""Automation script for the <SKILL> skill.

Front-loads everything mechanical the skill needs so a fresh agent runs one
command instead of many. Standard library only — no pip installs.

Usage:
    python <skill>.py gather            # read-only: print gathered context as JSON
    python <skill>.py schema            # print the JSON Schema for `gather` output
    python <skill>.py <action> [flags]  # one deterministic mutation

stdout is JSON only (pipe it to jq); all logs/diagnostics go to stderr.
"""

import argparse
import json
import subprocess
import sys
from pathlib import Path

SKILL = "<skill>"        # merge key when composing skills — keep unique & stable
VERSION = 1              # bump when the `data` shape changes
STATE_PATH = Path(__file__).with_name("state.json")


# --- helpers ---------------------------------------------------------------

def log(msg):
    """Diagnostics go to stderr so stdout stays clean JSON."""
    print(msg, file=sys.stderr)


def run(cmd, **kw):
    """Shell out for git/tea/gh/linters. Returns CompletedProcess; never raises on
    non-zero (check .returncode). Pass a list, not a string."""
    return subprocess.run(cmd, capture_output=True, text=True, **kw)


def emit(obj):
    """Print one JSON object to stdout and flush."""
    json.dump(obj, sys.stdout, indent=2, sort_keys=False)
    sys.stdout.write("\n")
    sys.stdout.flush()


def load_state():
    """Return persisted state, or {} if missing/malformed — never raise."""
    try:
        return json.loads(STATE_PATH.read_text()).get("state", {})
    except (FileNotFoundError, ValueError):
        return {}


def save_state(state):
    STATE_PATH.write_text(
        json.dumps({"skill": SKILL, "version": VERSION, "state": state}, indent=2)
    )


# --- collectors (fill these in) -------------------------------------------
# Each collector reads some state and returns a (key, value) for `data`, or
# records into `errors` and returns an empty slice. Keep them read-only.

def collect_example(errors):
    cp = run(["git", "status", "--porcelain"])
    if cp.returncode != 0:
        errors.append({"source": "git-status", "message": cp.stderr.strip()})
        return "git", None
    return "git", {"dirty": bool(cp.stdout.strip())}


COLLECTORS = [
    collect_example,
    # add more collectors here
]


def cmd_gather(args):
    data, errors = {}, []
    for collector in COLLECTORS:
        try:
            key, value = collector(errors)
            data[key] = value
        except Exception as exc:  # a broken collector must not sink the whole run
            errors.append({"source": collector.__name__, "message": str(exc)})
    emit({"skill": SKILL, "version": VERSION, "data": data, "errors": errors})
    return 0


# --- actions (fill these in) ----------------------------------------------
# One subcommand per deterministic mutation. Each prints a small result object.

def cmd_action_example(args):
    # do one mechanical thing, e.g. run(["tea", "comment", ...])
    emit({"ok": True, "skill": SKILL, "action": "example", "result": {}})
    return 0


# --- schema ----------------------------------------------------------------

def cmd_schema(args):
    emit({
        "$schema": "http://json-schema.org/draft-07/schema#",
        "type": "object",
        "required": ["skill", "version", "data", "errors"],
        "properties": {
            "skill": {"const": SKILL},
            "version": {"type": "integer"},
            "data": {"type": "object"},       # tighten per skill
            "errors": {
                "type": "array",
                "items": {
                    "type": "object",
                    "required": ["source", "message"],
                    "properties": {
                        "source": {"type": "string"},
                        "message": {"type": "string"},
                    },
                },
            },
        },
    })
    return 0


# --- dispatch --------------------------------------------------------------

def main(argv=None):
    parser = argparse.ArgumentParser(description=f"{SKILL} automation script")
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("gather", help="read-only: print gathered context as JSON")
    sub.add_parser("schema", help="print the JSON Schema for gather output")
    p_ex = sub.add_parser("example", help="a deterministic mutation")
    # p_ex.add_argument("--issue", type=int, required=True)

    handlers = {
        "gather": cmd_gather,
        "schema": cmd_schema,
        "example": cmd_action_example,
    }
    args = parser.parse_args(argv)
    return handlers[args.command](args)


if __name__ == "__main__":
    sys.exit(main())
