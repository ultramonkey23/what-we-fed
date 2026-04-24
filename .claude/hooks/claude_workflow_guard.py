#!/usr/bin/env python3
"""Advisory Claude Code hook for WHAT WE FED workflow reminders."""

from __future__ import annotations

import json
import os
import sys
from pathlib import Path


COMBAT_CRITICAL = (
    "scenes/combat/combatscene.gd",
    "scenes/combat/playercombat.gd",
    "scenes/combat/lanemanager.gd",
    "systems/combatmeter.gd",
    "systems/songconductor.gd",
    "systems/supporteffectresolver.gd",
)

HUD_READABILITY = (
    "scenes/ui/",
    "systems/combatpresent",
    "systems/combathud",
    "systems/uistyle.gd",
    "systems/hudpanelart.gd",
)

VISUAL_EFFECTS = (
    "art/",
    "assets/",
    "systems/presentation/",
    ".gdshader",
    ".theme",
    ".tres",
    ".png",
    ".webp",
    ".jpg",
)

DATA_CONTENT = (
    "data/",
    "systems/performancerewarddirector.gd",
    "systems/rungrowth.gd",
    "systems/predationpool.gd",
)


def _extract_path(payload: dict) -> str:
    tool_input = payload.get("tool_input") or {}
    for key in ("file_path", "path"):
        value = tool_input.get(key)
        if isinstance(value, str):
            return value
    return ""


def _normalize(path_text: str) -> str:
    project_dir = os.environ.get("CLAUDE_PROJECT_DIR", "")
    try:
        path = Path(path_text)
        if path.is_absolute() and project_dir:
            path = path.relative_to(project_dir)
        return path.as_posix().lower()
    except Exception:
        return path_text.replace("\\", "/").lower()


def _matches(path: str, patterns: tuple[str, ...]) -> bool:
    return any(pattern in path for pattern in patterns)


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except Exception:
        return 0

    path = _normalize(_extract_path(payload))
    if not path:
        return 0

    notes: list[str] = []

    if "scenes/combat/combatscene.gd" in path:
        notes.append(
            "WHAT WE FED caution: CombatScene.gd is a bottleneck file. State the exact combat contract protected, keep the edit bounded, and validate with smoke_project.bat plus debug_harness/run_project when timing or feel is claimed."
        )
    elif _matches(path, COMBAT_CRITICAL):
        notes.append(
            "WHAT WE FED combat-critical edit: verify timing truth, input response, lane/readability, and support clarity. Run smoke_project.bat at minimum."
        )

    if _matches(path, HUD_READABILITY) or _matches(path, VISUAL_EFFECTS):
        notes.append(
            "Readability-sensitive edit: include a HUD/VFX readability or feel-check note. Visual quality claims need screenshot/capture evidence or must be labeled static-only."
        )

    if _matches(path, DATA_CONTENT):
        notes.append(
            "Data/content edit: preserve stable IDs and resource paths. Run validate_data.bat when schemas, IDs, weights, or content lookups changed."
        )

    if notes:
        print("\n".join(f"[Claude workflow guard] {note}" for note in notes))

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
