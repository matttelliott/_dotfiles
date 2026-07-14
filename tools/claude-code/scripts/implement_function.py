#!/usr/bin/env uv run


import difflib
import json
import os
import shutil
import subprocess
import sys
from typing import TypedDict


class Change(TypedDict):
    location: str
    diff: str


def _log(*args: object) -> None:
    """Human/diagnostic output goes to stderr so stdout stays parsable JSON."""
    print(*args, file=sys.stderr, flush=True)


def parse_location(location: str) -> tuple[str, int | None, int | None]:
    """Split `/path/to/file.ext:line:column` into (file, line, column).

    Trailing numeric segments are treated as line then column. A path with no
    trailing numbers yields (path, None, None). Colons inside the path are kept.
    """
    segs = location.split(":")
    nums: list[int] = []
    while len(segs) > 1 and segs[-1].isdigit():
        nums.insert(0, int(segs.pop()))
    file = ":".join(segs)
    line = nums[0] if len(nums) >= 1 else None
    col = nums[1] if len(nums) >= 2 else None
    return file, line, col


def _repo_root(start_dir: str) -> str:
    try:
        out = subprocess.run(
            ["git", "-C", start_dir, "rev-parse", "--show-toplevel"],
            capture_output=True,
            text=True,
            check=True,
        )
        return out.stdout.strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return start_dir


def _build_prompt(rel_file: str, line: int | None) -> str:
    target = f"{rel_file}:{line}" if line is not None else rel_file
    at = f"at line {line} of `{rel_file}`" if line is not None else f"in `{rel_file}`"
    return (
        f"Implement the single function or test located {at} (target: {target}).\n"
        "\n"
        "Requirements:\n"
        f"- Base the implementation on the name, comments, docstring, and signature "
        "of that function or test.\n"
        "- Implement ONLY that one function or test. Do not add, remove, or modify "
        "any other code, function, import, or file.\n"
        "- You may read any file in the repository for context.\n"
        f"- You may only edit `{rel_file}`.\n"
        "- Replace any placeholder/stub body with a correct, working implementation.\n"
    )


def _diff_to_changes(rel_file: str, before: str, after: str) -> list[Change]:
    """Convert a before/after unified diff of one file into per-hunk Changes.

    Each hunk becomes one Change whose location points at the hunk's starting
    line in the new file and whose diff is the hunk text.
    """
    diff_lines = list(
        difflib.unified_diff(
            before.splitlines(keepends=True),
            after.splitlines(keepends=True),
            fromfile=f"a/{rel_file}",
            tofile=f"b/{rel_file}",
        )
    )
    if not diff_lines:
        return []

    header = "".join(diff_lines[:2])  # ---/+++ lines
    changes: list[Change] = []
    current: list[str] = []
    new_start = 0

    def flush() -> None:
        if current:
            changes.append(
                Change(
                    location=f"{rel_file}:{new_start}",
                    diff=header + "".join(current),
                )
            )

    for line in diff_lines[2:]:
        if line.startswith("@@"):
            flush()
            current = [line]
            # @@ -a,b +c,d @@  -> new_start = c
            try:
                plus = line.split("+", 1)[1]
                new_start = int(plus.split(",", 1)[0].split(" ", 1)[0])
            except (IndexError, ValueError):
                new_start = 0
        else:
            current.append(line)
    flush()
    return changes


def implement_function(location: str, model_size="l") -> list[Change]:
    """
    Takes a file location `/path/to/file.ext:line:column`
    Takes an optional param model_size xs/s/m/l/xl
        - for anthropic/claude : xl=fable, l=opus, m=sonnet, s/xs = haiku, default=l
    Invokes AI Agent to implement function or test at location based on name, comments, and signature
    Returns locations and diffs. Only includes changes made by the agent, not the full git diff.
    Is well behaved when called from cli. Prints parsable JSON to stdout, all outher output to stderr.
    Agent only implements the function or test at the location provided
    Agent can read any file in the repo. Agent can only write to the file provided.
    """
    claude_bin = shutil.which("claude")
    if claude_bin is None:
        raise RuntimeError("`claude` CLI not found on PATH")

    file, line, _col = parse_location(location)
    # realpath so the target and the git root agree through symlinks
    # (e.g. macOS /var -> /private/var); otherwise the relative path and the
    # tool allow-list below would not match the paths the agent edits.
    abs_file = os.path.realpath(file)
    if not os.path.isfile(abs_file):
        raise FileNotFoundError(f"target file does not exist: {abs_file}")

    root = os.path.realpath(_repo_root(os.path.dirname(abs_file)))
    rel_file = os.path.relpath(abs_file, root)

    with open(abs_file, encoding="utf-8") as fh:
        before = fh.read()

    # Restrict the agent: read anything, but only edit the one target file.
    # In --print mode, tool calls outside this allow-list are auto-denied
    # rather than prompting, so writes to other files cannot happen.
    allowed = [
        "Read",
        "Grep",
        "Glob",
        f"Edit({abs_file})",
        f"Edit({rel_file})",
        f"Write({abs_file})",
        f"Write({rel_file})",
    ]

    cmd = [
        claude_bin,
        "-p",
        _build_prompt(rel_file, line),
        "--output-format",
        "text",
        "--allowed-tools",
        *allowed,
    ]
    # Map the abstract size to an Anthropic/Claude model alias per the docstring.
    # An explicit IMPLEMENT_FUNCTION_MODEL env var always wins.
    size_to_model = {
        "xl": "fable",
        "l": "opus",
        "m": "sonnet",
        "s": "haiku",
        "xs": "haiku",
    }
    model = os.environ.get("IMPLEMENT_FUNCTION_MODEL") or size_to_model.get(
        model_size, size_to_model["l"]
    )
    if model:
        cmd += ["--model", model]

    timeout = float(os.environ.get("IMPLEMENT_FUNCTION_TIMEOUT", "600"))

    _log(f"[implement_function] target: {rel_file}:{line}")
    _log(f"[implement_function] repo root: {root}")
    result = subprocess.run(
        cmd,
        cwd=root,
        capture_output=True,
        text=True,
        timeout=timeout,
    )
    if result.stdout.strip():
        _log("[implement_function] agent output:")
        _log(result.stdout.rstrip())
    if result.stderr.strip():
        _log(result.stderr.rstrip())
    if result.returncode != 0:
        raise RuntimeError(f"agent exited with code {result.returncode}")

    with open(abs_file, encoding="utf-8") as fh:
        after = fh.read()

    return _diff_to_changes(rel_file, before, after)


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        _log("usage: implement_function.py /path/to/file.ext:line:column")
        return 2
    try:
        changes = implement_function(argv[1])
    except Exception as exc:  # noqa: BLE001 - surface any failure cleanly to CLI
        _log(f"error: {exc}")
        return 1
    json.dump(changes, sys.stdout)
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
