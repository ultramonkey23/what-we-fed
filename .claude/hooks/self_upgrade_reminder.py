#!/usr/bin/env python3
"""Advisory hook: remind agents to run the Self-Upgrade Check before final report."""

from __future__ import annotations

import json
import sys


REMINDER = (
    "[Living Command Loop] Include the Self-Upgrade Check in your Auditor's Report. "
    "Run /self-upgrade-check or see docs/ai/LIVING_COMMAND_LOOP.md."
)


def _had_tool_use(payload: dict) -> bool:
    """Return True if the session transcript contains any tool use, suggesting implementation work."""
    messages = payload.get("messages", [])
    return any(
        isinstance(msg.get("content"), list)
        and any(block.get("type") == "tool_use" for block in msg["content"])
        for msg in messages
    )


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except Exception:
        payload = {}

    # Only remind when tool use happened — skip for pure conversation turns.
    if _had_tool_use(payload):
        print(REMINDER)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
