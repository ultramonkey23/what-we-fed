#!/usr/bin/env python3
"""
check_soul_integrity.py — WHAT WE FED Soul Integrity Scanner
Scans active AI docs and agent entrypoints for stale doctrine and generic drift.
Ignores docs/ai/archive_legacy/.

Usage:
  python tools/ai/check_soul_integrity.py [repo_root]

Exit codes:
  0 — PASS (no violations)
  1 — WARNINGS (drift detected in active docs)
  2 — FAIL (hard violations found)
"""

from __future__ import annotations

import re
import sys
from pathlib import Path


# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

SCAN_ROOTS = [
    "AGENTS.md",
    "CLAUDE.md",
    "GEMINI.md",
    "docs/ai",
    "docs/LIVING_CODEX_PLAYER_VESSEL.md",
    ".gemini/agents",
    ".claude/commands",
    ".github",
]

IGNORE_PATHS = [
    "docs/ai/archive_legacy",
]

# Patterns that must NOT appear in active AI context (warn/fail)
FORBIDDEN_PATTERNS: list[tuple[str, str, str, str]] = [
    # (id, label, regex, level)
    (
        "F001",
        "Premium Menace declared as base/art style",
        r"Premium\s+Menace\s+(is|are|=)\s+(the\s+)?(base|art|current|default)\s+style",
        "FAIL",
    ),
    (
        "F002",
        "Base style declared as Premium Menace",
        r"(base|art|current|default)\s+style\s+(is|are|=)\s+(the\s+)?[\"']?Premium\s+Menace",
        "FAIL",
    ),
    (
        "F003",
        "Strict lane combat declared as current design",
        r"strict\s+lane\s+combat\s+(is|remains?|was|=)\s+(still\s+)?(the\s+)?(current|active|live)",
        "WARN",
    ),
    (
        "F004",
        "Active design declared as strict lane combat",
        r"(current|active|live)\s+(design|combat|system)\s+(is|=)\s+(still\s+)?strict\s+lane\s+combat",
        "WARN",
    ),
    (
        "F005",
        "LaneManager.gd as current spatial authority",
        r"LaneManager\.gd.{0,60}(current\s+authority|owns\s+(spatial|zone|lane\s+coord)|is\s+the\s+(spatial|zone)\s+manager|active\s+(spatial|zone)\s+manager)",
        "WARN",
    ),
    (
        "F006",
        "Humanoid player framing",
        r"player.{0,40}(is\s+a\s+|as\s+a\s+)(humanoid|human\s+character|person|warrior|knight|fighter|mage)",
        "FAIL",
    ),
    (
        "F007",
        "Slime player identity",
        r"player.{0,40}(is\s+a\s+|as\s+a\s+)slime",
        "FAIL",
    ),
    (
        "F008",
        "Ghost player identity",
        r"player.{0,40}(is\s+a\s+|as\s+a\s+)ghost",
        "FAIL",
    ),
    (
        "F009",
        "Mobile game framing (positive assertion)",
        r"(is\s+a\s+mobile\s+game|designed?\s+for\s+mobile|mobile\s+RPG\b|mobile\s+platform|mobile[-\s]first)",
        "WARN",
    ),
    (
        "F010",
        "Strict lane-slot occupancy as current spatial design",
        r"(must\s+strictly\s+occupy\s+Lanes?|strictly\s+occupy\s+Lanes?\s+0|Threats?.{0,40}strictly\s+occupy\s+Lanes?)",
        "WARN",
    ),
    (
        "F011",
        "AI_CONTROL_PLANE.md cited as live routing source (file no longer exists)",
        r"(Routing\s+rules?|routing\s+via|route\s+via|see\s+also\s*:)\s*[`\"]?docs/ai/AI_CONTROL_PLANE\.md",
        "WARN",
    ),
    (
        "F012",
        "Quig creator-reference rule instructs using 'Cody' instead of 'the monkeydog'",
        r"Quig.{0,150}(must\s+call|should\s+call)\s+(?:them\s+)?[\"']?Cody[\"']?",
        "FAIL",
    ),
]

# Terms that MUST exist somewhere in the active AI context corpus (aggregated)
REQUIRED_CORPUS_TERMS: list[tuple[str, str, str]] = [
    # (id, label, regex)
    ("R001", "Legendary Pixel Fable Ink", r"Legendary\s+Pixel\s+Fable\s+Ink"),
    ("R002", "Fed Anomaly or Vessel identity", r"(Fed\s+Anomaly|The\s+Fed\s+Anomaly|Vessel)"),
    ("R003", "Non-humanoid player", r"non.humanoid"),
    ("R004", "Spatial / 360-degree combat", r"(spatial\s+combat|360.degree|360°)"),
    ("R005", "ZoneManager doctrine", r"ZoneManager"),
    ("R006", "Quig presence", r"\bQuig\b"),
    ("R007", "the monkeydog creator reference rule", r"the\s+monkeydog"),
    ("R008", "feeding as core player mechanic", r"\bfeed(ing|s)?\b"),
    ("R009", "bonding / Bond mechanic", r"\bBond\b"),
    ("R010", "mutation / mutating as core identity", r"(mutati|mutating|mutation)"),
]


# ---------------------------------------------------------------------------
# Scanning logic
# ---------------------------------------------------------------------------

def collect_files(repo_root: Path) -> list[Path]:
    """Return all .md files in scan roots, excluding ignored paths."""
    files: list[Path] = []
    ignore_abs = [repo_root / p for p in IGNORE_PATHS]

    for root_rel in SCAN_ROOTS:
        target = repo_root / root_rel
        if target.is_file():
            files.append(target)
        elif target.is_dir():
            for f in sorted(target.rglob("*.md")):
                if not any(f.is_relative_to(ign) for ign in ignore_abs):
                    files.append(f)

    return files


def check_forbidden(content: str, path: Path, flags: int = re.IGNORECASE) -> list[dict]:
    hits = []
    for pid, label, pattern, level in FORBIDDEN_PATTERNS:
        for m in re.finditer(pattern, content, flags):
            line_num = content[: m.start()].count("\n") + 1
            hits.append(
                {
                    "id": pid,
                    "level": level,
                    "label": label,
                    "file": str(path),
                    "line": line_num,
                    "snippet": m.group(0)[:120].replace("\n", " "),
                }
            )
    return hits


def check_required_corpus(corpus: str, flags: int = re.IGNORECASE) -> list[dict]:
    missing = []
    for rid, label, pattern in REQUIRED_CORPUS_TERMS:
        if not re.search(pattern, corpus, flags):
            missing.append({"id": rid, "label": label})
    return missing


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main(argv: list[str]) -> int:
    # Ensure UTF-8 output on Windows where cp1252 is the default console encoding.
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")

    repo_root = Path(argv[1]).resolve() if len(argv) > 1 else Path.cwd()

    if not repo_root.exists():
        print(f"ERROR: repo root not found: {repo_root}")
        return 2

    files = collect_files(repo_root)
    if not files:
        print("WARNING: no active AI doc files found to scan.")
        return 1

    print(f"[soul-integrity] scanning {len(files)} active AI doc/entrypoint files ...")

    all_forbidden: list[dict] = []
    corpus_parts: list[str] = []

    for f in files:
        try:
            content = f.read_text(encoding="utf-8", errors="replace")
        except Exception as exc:
            print(f"  SKIP (read error): {f}  — {exc}")
            continue

        corpus_parts.append(content)
        hits = check_forbidden(content, f)
        all_forbidden.extend(hits)

    corpus = "\n".join(corpus_parts)
    missing_required = check_required_corpus(corpus)

    # ---- Report ----
    fail = False
    warn = False

    if all_forbidden:
        print("\n--- FORBIDDEN PATTERNS IN ACTIVE DOCS ---")
        for hit in all_forbidden:
            tag = f"[{hit['level']}] {hit['id']}"
            print(f"  {tag} {hit['label']}")
            print(f"         File: {hit['file']}:{hit['line']}")
            print(f"         Match: {hit['snippet']!r}")
        fail = any(h["level"] == "FAIL" for h in all_forbidden)
        warn = any(h["level"] == "WARN" for h in all_forbidden)

    if missing_required:
        print("\n--- REQUIRED TERMS MISSING FROM ACTIVE CORPUS ---")
        for m in missing_required:
            print(f"  [WARN] {m['id']} — {m['label']}")
        warn = True

    if not all_forbidden and not missing_required:
        print("[soul-integrity] PASS — no drift detected in active AI context.")
        return 0

    # Archived docs note
    archive_path = repo_root / "docs" / "ai" / "archive_legacy"
    if archive_path.exists():
        print(
            "\nNOTE: docs/ai/archive_legacy/ was excluded. "
            "Archived docs may contain old terms and are intentionally ignored."
        )

    if fail:
        print("\n[soul-integrity] FAIL — hard violations in active context.")
        return 2
    if warn:
        print("\n[soul-integrity] WARN — drift risk in active context.")
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
