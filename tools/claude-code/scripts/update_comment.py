#!/usr/bin/env uv run


import json
import os
import shutil
import subprocess
import sys

from implement_function import (Change, _diff_to_changes, _log, _repo_root,
                                parse_location)


def update_comment(location: str, model_size="s") -> list[Change]:
    """
    Updates a comment or docstring using an AI agent.

    Takes a file location in format `/path/to/file.ext:line:column` and invokes an AI agent
    to rewrite the comment or docstring at that location to match the current implementation.

    Args:
        location: File location as `/path/to/file.ext:line:column`
        model_size: Model size (xs/s/m/l/xl, default=s)
            - Maps to Claude models: xl=fable, l=opus, m=sonnet, s/xs=haiku
            - Can be overridden by UPDATE_COMMENT_MODEL env var

    Returns:
        List of Change objects representing diffs between before and after.
        Only includes changes made by the agent, not the full git diff.

    Environment Variables:
        UPDATE_COMMENT_MODEL: Override model selection
        UPDATE_COMMENT_TIMEOUT: Timeout in seconds (default 600)

    The agent can read any file in the repo but can only edit the target file.
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

    target = f"{rel_file}:{line}" if line is not None else rel_file
    at = f"at line {line} of `{rel_file}`" if line is not None else f"in `{rel_file}`"
    prompt = (
        f"Update the comment or docstring located {at} (target: {target}) so it "
        "accurately describes the current implementation.\n"
        "\n"
        "Requirements:\n"
        "- Read the code the comment documents and rewrite the comment so it "
        "matches what that implementation actually does.\n"
        "- Update ONLY the comment or docstring at that location. Do not add, "
        "remove, or modify any code, logic, function, import, or other comment.\n"
        "- You may read any file in the repository for context.\n"
        f"- You may only edit `{rel_file}`.\n"
    )

    cmd = [
        claude_bin,
        "-p",
        prompt,
        "--output-format",
        "text",
        "--allowed-tools",
        *allowed,
    ]
    # Map the abstract size to an Anthropic/Claude model alias per the docstring.
    # An explicit UPDATE_COMMENT_MODEL env var always wins.
    size_to_model = {
        "xl": "fable",
        "l": "opus",
        "m": "sonnet",
        "s": "haiku",
        "xs": "haiku",
    }
    model = os.environ.get("UPDATE_COMMENT_MODEL") or size_to_model.get(
        model_size, size_to_model["s"]
    )
    if model:
        cmd += ["--model", model]

    timeout = float(os.environ.get("UPDATE_COMMENT_TIMEOUT", "600"))

    _log(f"[update_comment] target: {rel_file}:{line}")
    _log(f"[update_comment] repo root: {root}")
    result = subprocess.run(
        cmd,
        cwd=root,
        capture_output=True,
        text=True,
        timeout=timeout,
    )
    if result.stdout.strip():
        _log("[update_comment] agent output:")
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
        _log("usage: update_comment.py /path/to/file.ext:line:column")
        return 2
    try:
        changes = update_comment(argv[1])
    except Exception as exc:  # noqa: BLE001 - surface any failure cleanly to CLI
        _log(f"error: {exc}")
        return 1
    json.dump(changes, sys.stdout)
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
