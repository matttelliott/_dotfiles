"""Shared state + path helpers for find-features scripts.

Session files live at state/sessions/<session-id>.json. The currently-active
session id is tracked in state/active-session.json. Callers can either rely on
the active pointer (the common case) or pass an explicit session_id.

Install manifests live at state/manifests/<session-id>/<suggestion-id>.json.
"""

from __future__ import annotations

import json
import os
import subprocess
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


SKILL_DIR = Path(__file__).resolve().parent.parent
STATE_DIR = SKILL_DIR / "state"
SESSIONS_DIR = STATE_DIR / "sessions"
ACTIVE_POINTER = STATE_DIR / "active-session.json"
MANIFEST_DIR = STATE_DIR / "manifests"


def repo_root() -> Path:
    cur = Path(os.getcwd()).resolve()
    for candidate in [cur, *cur.parents]:
        if (candidate / ".git").exists():
            return candidate
    fallback = SKILL_DIR.parent.parent.parent
    if (fallback / ".git").exists():
        return fallback
    raise RuntimeError(f"could not locate repo root from cwd={cur}")


def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def _session_file(session_id: str) -> Path:
    if not session_id or "/" in session_id or session_id.startswith("."):
        raise ValueError(f"invalid session_id: {session_id!r}")
    return SESSIONS_DIR / f"{session_id}.json"


def active_session_id() -> str:
    if not ACTIVE_POINTER.exists():
        raise FileNotFoundError(
            "no active session — run `session_cli new --intent ...` first")
    with ACTIVE_POINTER.open() as f:
        return json.load(f)["session_id"]


def set_active_session_id(session_id: str) -> None:
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    # Per-process tmp name so concurrent writers don't race on the rename.
    tmp = ACTIVE_POINTER.with_suffix(f".json.tmp.{os.getpid()}")
    with tmp.open("w") as f:
        json.dump({"session_id": session_id}, f)
    tmp.replace(ACTIVE_POINTER)


def load_session(session_id: str | None = None) -> dict[str, Any]:
    sid = session_id or active_session_id()
    path = _session_file(sid)
    if not path.exists():
        raise FileNotFoundError(f"no session at {path}")
    with path.open() as f:
        return json.load(f)


def save_session(data: dict[str, Any]) -> None:
    sid = data["session_id"]
    SESSIONS_DIR.mkdir(parents=True, exist_ok=True)
    path = _session_file(sid)
    tmp = path.with_suffix(f".json.tmp.{os.getpid()}")
    with tmp.open("w") as f:
        json.dump(data, f, indent=2)
    tmp.replace(path)


def new_session(intent: str) -> dict[str, Any]:
    # Include microseconds so back-to-back calls don't collide on session_id.
    session_id = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
    data = {
        "session_id": session_id,
        "intent": intent,
        "created_at": now_iso(),
        "suggestions": [],
        "selected": [],
        "trials": [],
    }
    save_session(data)
    set_active_session_id(session_id)
    return data


def manifest_path(session_id: str, suggestion_id: str) -> Path:
    d = MANIFEST_DIR / session_id
    d.mkdir(parents=True, exist_ok=True)
    return d / f"{suggestion_id}.json"


def load_manifest(path: Path) -> dict[str, Any]:
    with path.open() as f:
        return json.load(f)


def save_manifest(path: Path, data: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w") as f:
        json.dump(data, f, indent=2)


def detect_os() -> str:
    """Return one of: darwin, debian, arch, unknown."""
    import platform
    system = platform.system()
    if system == "Darwin":
        return "darwin"
    if system == "Linux":
        for release in ("/etc/os-release",):
            try:
                text = Path(release).read_text()
            except OSError:
                continue
            lower = text.lower()
            if "arch" in lower or "manjaro" in lower:
                return "arch"
            if "debian" in lower or "ubuntu" in lower:
                return "debian"
    return "unknown"


def run(cmd: list[str] | str, *, check: bool = True, capture: bool = False,
        cwd: Path | None = None) -> subprocess.CompletedProcess:
    return subprocess.run(
        cmd,
        check=check,
        shell=isinstance(cmd, str),
        capture_output=capture,
        text=True,
        cwd=cwd,
    )
