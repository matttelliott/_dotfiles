#!/usr/bin/env python3
"""Dump raw material about every tool in the repo for Claude to reason over.

This is NOT a suggestion engine. It's a data-gathering script. It reads each
tools/<name>/ directory and emits a JSON structure with enough context for
Claude to understand what each tool does and what's already configured.

Usage:
    python -m scripts.scan_tools              # full dump, all tools
    python -m scripts.scan_tools --names-only # just the tool names (cheap)
    python -m scripts.scan_tools --tool tmux  # single tool, full detail

Why Claude reads this instead of grepping directly: the scan is deterministic
and cheap to rerun, so the skill can cache the result and avoid Claude
re-exploring the tree on every suggestion pass.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from state import repo_root  # noqa: E402


# Files we care about when summarizing a tool. Everything else is ignored to
# keep the payload small. Add to this list if tools start using new patterns.
INTERESTING_SUFFIXES = (".yml", ".yaml", ".zsh", ".sh", ".bash", ".lua",
                        ".toml", ".conf", ".cfg", ".json", ".j2", ".md")

# Cap per-file bytes so one huge config doesn't blow out the payload.
FILE_BYTE_CAP = 20_000


def summarize_tool(tool_dir: Path, *, include_contents: bool) -> dict:
    name = tool_dir.name
    entry = {"name": name, "path": str(tool_dir), "files": []}
    for item in sorted(tool_dir.rglob("*")):
        if item.is_dir():
            continue
        rel = item.relative_to(tool_dir)
        # Skip vendored / generated trees — they're huge and rarely informative.
        if any(part in {".git", "node_modules", "__pycache__", ".venv", "site-packages"}
               for part in rel.parts):
            continue
        file_info = {"path": str(rel), "suffix": item.suffix}
        if include_contents and item.suffix in INTERESTING_SUFFIXES:
            try:
                text = item.read_text(errors="replace")
            except OSError as e:
                file_info["error"] = str(e)
            else:
                truncated = len(text.encode()) > FILE_BYTE_CAP
                file_info["content"] = text[:FILE_BYTE_CAP]
                if truncated:
                    file_info["truncated"] = True
        entry["files"].append(file_info)
    return entry


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--tool", help="limit to a single tool name")
    parser.add_argument("--names-only", action="store_true",
                        help="emit just the tool names, no file contents")
    args = parser.parse_args(argv)

    tools_dir = repo_root() / "tools"
    if not tools_dir.is_dir():
        print(f"tools dir not found at {tools_dir}", file=sys.stderr)
        return 1

    candidates = sorted(p for p in tools_dir.iterdir() if p.is_dir())
    if args.tool:
        candidates = [p for p in candidates if p.name == args.tool]
        if not candidates:
            print(f"no tool named {args.tool!r} in {tools_dir}", file=sys.stderr)
            return 1

    if args.names_only:
        payload = {"tools": [p.name for p in candidates]}
    else:
        payload = {"tools": [summarize_tool(p, include_contents=True) for p in candidates]}

    json.dump(payload, sys.stdout, indent=2)
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
