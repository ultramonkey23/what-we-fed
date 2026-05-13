#!/usr/bin/env python3
"""Advisory Claude Code hook for WHAT WE FED workflow reminders."""

from __future__ import annotations

import json
import os
import sys
from pathlib import Path


SIGNAL_CRITICAL = (
    "autoloads/eventbus.gd",
)

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

GDSCRIPT_GENERAL = (".gd",)

# Stale doctrine phrases that should not appear in newly-written content.
# (label, pattern, file extensions to check)
STALE_CONTENT_PATTERNS: tuple[tuple[str, str, tuple[str, ...]], ...] = (
    (
        "stale lane combat framing",
        r"strict\s+lane\s+combat.{0,80}(current|active|live)",
        (".md", ".gd"),
    ),
    (
        "LaneManager.gd framed as current spatial authority",
        r"LaneManager\.gd.{0,60}(current\s+authority|owns\s+(spatial|zone)|is\s+the\s+(spatial|zone)\s+manager)",
        (".md", ".gd"),
    ),
    (
        "retired art style label 'Premium Menace'",
        r"Premium\s+Menace.{0,60}(base\s+style|art\s+style|is\s+the\s+style)",
        (".md",),
    ),
    (
        "stale lane-slot occupancy doctrine",
        r"(must\s+strictly\s+occupy\s+Lanes?|strictly\s+occupy\s+Lanes?\s+0)",
        (".md", ".gd"),
    ),
    (
        "stale AI_CONTROL_PLANE.md reference (file no longer exists)",
        r"AI_CONTROL_PLANE\.md",
        (".md",),
    ),
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


def _check_stale_content(payload: dict, path: str) -> list[str]:
    """Warn if newly-written content contains stale doctrine phrases."""
    import re

    tool_input = payload.get("tool_input") or {}
    written = tool_input.get("new_string") or tool_input.get("content") or ""
    if not written:
        return []

    ext = "." + path.rsplit(".", 1)[-1] if "." in path else ""
    warnings = []
    for label, pattern, exts in STALE_CONTENT_PATTERNS:
        if exts and ext not in exts:
            continue
        if re.search(pattern, written, re.IGNORECASE):
            warnings.append(
                f"Content contains {label} — verify this is intentional and not stale doctrine."
            )
    return warnings


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except Exception:
        return 0

    path = _normalize(_extract_path(payload))
    if not path:
        return 0

    notes: list[str] = []

    # Stale content detection (check what is being written, not just the path)
    notes.extend(_check_stale_content(payload, path))

    if _matches(path, SIGNAL_CRITICAL):
        notes.append(
            "EventBus.gd edit: signal contract may have changed. After implementation, regenerate docs/ai/SIGNAL_MAP.md by running from what-we-fed/: python ../tools/ai/generate_signal_map.py — then update Curated Notes if contracts changed. Required before SYMBIOTE Firmware Interlock in any GODLY run."
        )

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

    already_warned_gd = bool(notes)
    if _matches(path, GDSCRIPT_GENERAL) and not already_warned_gd:
        notes.append(
            "GDScript edit: confirm typed variables/params, @onready/@export safety, signal connected before emit, and no frame-dependent logic outside SongConductor."
        )

    if notes:
        print("\n".join(f"[Claude workflow guard] {note}" for note in notes))

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
