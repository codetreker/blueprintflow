#!/usr/bin/env python3
"""Codex hook state for Blueprintflow Teamlead continuity."""

from __future__ import annotations

import hashlib
import json
import os
import re
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


def now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def read_stdin_json() -> dict[str, Any]:
    raw = sys.stdin.read().strip()
    if not raw:
        return {}
    try:
        value = json.loads(raw)
    except json.JSONDecodeError:
        return {}
    return value if isinstance(value, dict) else {}


def safe_session_id(session_id: str) -> str:
    if re.fullmatch(r"[A-Za-z0-9_.-]{1,160}", session_id):
        return session_id
    return hashlib.sha256(session_id.encode("utf-8")).hexdigest()


def state_root() -> Path:
    plugin_data = os.environ.get("PLUGIN_DATA")
    if plugin_data:
        return Path(plugin_data).expanduser() / "sessions"
    codex_home = os.environ.get("CODEX_HOME")
    base = Path(codex_home).expanduser() if codex_home else Path.home() / ".codex"
    return base / "blueprintflow" / "sessions"


def state_path(session_id: str) -> Path:
    return state_root() / f"{safe_session_id(session_id)}.json"


def load_state(session_id: str) -> dict[str, Any]:
    path = state_path(session_id)
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return {}
    return value if isinstance(value, dict) else {}


def write_state(session_id: str, state: dict[str, Any]) -> None:
    path = state_path(session_id)
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(
        "w", encoding="utf-8", dir=path.parent, delete=False
    ) as tmp:
        json.dump(state, tmp, indent=2, sort_keys=True)
        tmp.write("\n")
        temp_name = tmp.name
    os.replace(temp_name, path)


def emit(value: dict[str, Any]) -> None:
    print(json.dumps(value, separators=(",", ":")))


def control_payload(payload: dict[str, Any]) -> dict[str, Any]:
    control = payload.get("blueprintflow_continuity")
    return control if isinstance(control, dict) else {}


def control_action(payload: dict[str, Any]) -> str:
    action = control_payload(payload).get("action")
    return action.casefold() if isinstance(action, str) else ""


def session_id_from(payload: dict[str, Any]) -> str:
    session_id = payload.get("session_id")
    return session_id if isinstance(session_id, str) else ""


def cwd_from(payload: dict[str, Any]) -> str | None:
    cwd = payload.get("cwd")
    return cwd if isinstance(cwd, str) else None


def enable_continuity(payload: dict[str, Any]) -> None:
    session_id = session_id_from(payload)
    if not session_id:
        return
    state = load_state(session_id)
    control = control_payload(payload)
    scope = control.get("scope")
    write_state(
        session_id,
        {
            "active": True,
            "role": "teamlead",
            "mode": "continuous",
            "cwd": cwd_from(payload),
            "session_id": session_id,
            "scope": scope if isinstance(scope, str) else None,
            "started_at": state.get("started_at") or now_iso(),
            "activated_at": now_iso(),
            "last_turn_id": payload.get("turn_id"),
        },
    )
    emit(
        {
            "hookSpecificOutput": {
                "hookEventName": "UserPromptSubmit",
                "additionalContext": "Blueprintflow Teamlead continuity is enabled for this Codex session. Continue only inside the assigned Blueprintflow scope until structured control disables continuity.",
            },
            "suppressOutput": True,
        }
    )


def disable_continuity(payload: dict[str, Any]) -> None:
    session_id = session_id_from(payload)
    if not session_id:
        return
    state = load_state(session_id)
    if state:
        state.update(
            {
                "active": False,
                "deactivated_at": now_iso(),
                "last_turn_id": payload.get("turn_id"),
            }
        )
        write_state(session_id, state)
    emit(
        {
            "hookSpecificOutput": {
                "hookEventName": "UserPromptSubmit",
                "additionalContext": "Blueprintflow Teamlead continuity is disabled for this Codex session.",
            },
            "suppressOutput": True,
        }
    )


def handle_user_prompt_submit(payload: dict[str, Any]) -> None:
    action = control_action(payload)
    if action in {"enable", "start", "activate"}:
        enable_continuity(payload)
    elif action in {"disable", "stop", "pause"}:
        disable_continuity(payload)


def continuity_prompt(state: dict[str, Any]) -> str:
    cwd = state.get("cwd") if isinstance(state.get("cwd"), str) else "current cwd"
    return "\n".join(
        [
            "[teamlead continuity - 60s]",
            "Continue as Blueprintflow Teamlead in this Codex session.",
            f"Assigned scope cwd: {cwd}",
            "If assigned work has actionable role, PR, issue, CI, or task progress, route it through the matching bf-* skill.",
            "If nothing is actionable, sleep 60 seconds, then check only the assigned scope for new user messages, role completions, PR/CI changes, or tasks.",
            "Repeat until structured control disables continuity or the assigned work is closed.",
        ]
    )


def handle_stop(payload: dict[str, Any]) -> None:
    session_id = payload.get("session_id")
    if not isinstance(session_id, str) or not session_id:
        return

    state = load_state(session_id)
    if not state.get("active"):
        return
    if state.get("role") != "teamlead" or state.get("mode") != "continuous":
        return

    cwd = payload.get("cwd")
    state_cwd = state.get("cwd")
    if isinstance(cwd, str) and isinstance(state_cwd, str) and cwd != state_cwd:
        return

    state.update({"last_stop_at": now_iso(), "last_turn_id": payload.get("turn_id")})
    write_state(session_id, state)
    emit({"decision": "block", "reason": continuity_prompt(state)})


def main() -> int:
    action = sys.argv[1] if len(sys.argv) > 1 else ""
    payload = read_stdin_json()
    if action == "user-prompt-submit":
        handle_user_prompt_submit(payload)
    elif action == "enable":
        enable_continuity(payload)
    elif action == "disable":
        disable_continuity(payload)
    elif action == "stop":
        handle_stop(payload)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
