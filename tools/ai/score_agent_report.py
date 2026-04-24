#!/usr/bin/env python3
"""
score_agent_report.py — WHAT WE FED Agent Report Scorer
Usage:
  python tools/ai/score_agent_report.py path/to/report.txt
  cat report.txt | python tools/ai/score_agent_report.py
  python tools/ai/score_agent_report.py --help
"""

import sys
import re

HELP = """
WHAT WE FED — Agent Report Scorer
===================================
Scores an agent report for completeness, validation honesty,
stale-truth risk, and routing risk before it is accepted as repo truth.

Usage:
  python tools/ai/score_agent_report.py path/to/report.txt
  cat report.txt | python tools/ai/score_agent_report.py

Exit codes:
  0 — PASS
  1 — WARN
  2 — FAIL

Scoring rules are defined in: docs/ai/AGENT_REPORT_SCORECARD.md
""".strip()

FRAGILE_SYSTEMS = [
    "CombatScene.gd",
    "PlayerCombat.gd",
    "LaneManager.gd",
    "GameState.gd",
    "SongConductor.gd",
    "CombatContent.gd",
    "project.godot",
]

REQUIRED_FIELDS = [
    ("agent",               r"(?i)(Agent|Tool)\s*:"),
    ("date",                r"(?i)Date\s*:"),
    ("branch_commit",       r"(?i)(Branch(/commit)?|Commit)(\s+if\s+available)?\s*:"),
    ("task_type",           r"(?i)(Task\s*type|Task)\s*:"),
    ("files_inspected",     r"(?i)Files\s+inspected\s*:"),
    ("files_changed",       r"(?i)Files\s+changed\s*:"),
    ("validation_run",      r"(?i)Validation\s+run\s*:"),
    ("validation_level",    r"(?i)Validation\s+level\s*:"),
    ("validation_result",   r"(?i)Validation\s+result\s*:"),
    ("confirmed_truth",     r"(?i)Confirmed\s+repo\s+truth\s*:"),
    ("unverified",          r"(?i)Unverified\s+assumptions\s*:"),
    ("next_step",           r"(?i)(Recommended\s+next\s+step|What\s+should\s+happen\s+next)\s*:"),
    ("risks",               r"(?i)(Remaining\s+)?[Rr]isks\s*:"),
]

FIELD_LABELS = {
    "agent":            "Agent",
    "date":             "Date",
    "branch_commit":    "Branch/commit",
    "task_type":        "Task type",
    "files_inspected":  "Files inspected",
    "files_changed":    "Files changed",
    "validation_run":   "Validation run",
    "validation_level": "Validation level",
    "validation_result":"Validation result",
    "confirmed_truth":  "Confirmed repo truth",
    "unverified":       "Unverified assumptions",
    "next_step":        "Recommended next step",
    "risks":            "Risks",
}


def load_report(args):
    if len(args) == 2 and args[1] == "--help":
        print(HELP)
        sys.exit(0)
    if len(args) >= 2 and not args[1].startswith("-"):
        path = args[1]
        try:
            with open(path, "r", encoding="utf-8", errors="replace") as f:
                return f.read()
        except OSError as e:
            print(f"ERROR: Cannot read file: {e}", file=sys.stderr)
            sys.exit(2)
    if not sys.stdin.isatty():
        return sys.stdin.read()
    print("ERROR: Provide a file path or pipe report via stdin.", file=sys.stderr)
    print("       python tools/ai/score_agent_report.py --help", file=sys.stderr)
    sys.exit(2)


def detect_validation_level(text):
    m = re.search(r"(?i)Validation\s+level\s*:\s*([0-4]|UNKNOWN)", text)
    if m:
        val = m.group(1).strip()
        return val if val else "UNKNOWN"
    return "UNKNOWN"


def check_required_fields(text):
    present = {}
    for key, pattern in REQUIRED_FIELDS:
        present[key] = bool(re.search(pattern, text))
    return present


def field_has_content(text, pattern):
    """Return True if the field heading is followed by non-empty, non-placeholder content."""
    m = re.search(pattern, text)
    if not m:
        return False
    after = text[m.end():m.end() + 300]
    first_line = after.split("\n")[0].strip(" :\t")
    if not first_line or first_line in ("-", "—", "none", "n/a", "[path]", "[fact]"):
        next_lines = [l.strip() for l in after.split("\n")[1:4] if l.strip()]
        return bool(next_lines)
    return True


def detect_red_flags(text):
    flags = []
    tl = text.lower()

    # No files inspected content
    m = re.search(r"(?i)Files\s+inspected\s*:(.*?)(?=\n[A-Z]|\Z)", text, re.DOTALL)
    if m:
        block = m.group(1).strip()
        if not block or block in ("-", "—", "none", "n/a") or re.match(r"^\[.*\]$", block):
            flags.append("No files inspected listed")
    else:
        flags.append("No files inspected section found")

    # No files changed section content
    m2 = re.search(r"(?i)Files\s+changed\s*:(.*?)(?=\n[A-Z]|\Z)", text, re.DOTALL)
    if m2:
        block2 = m2.group(1).strip()
        if not block2 or block2 in ("-", "—") or re.match(r"^\[.*\]$", block2):
            flags.append("Files changed section is empty or placeholder")
    else:
        flags.append("No files changed section found")

    # No validation run
    m3 = re.search(r"(?i)Validation\s+run\s*:(.*?)(?=\n[A-Z]|\Z)", text, re.DOTALL)
    if m3:
        block3 = m3.group(1).strip()
        if not block3 or block3.lower() in ("none", "n/a", "-", "—") or re.match(r"^\[.*\]$", block3):
            flags.append("No validation run reported")
    else:
        flags.append("No validation run section found")

    # No validation result
    if not re.search(r"(?i)Validation\s+result\s*:\s*\S", text):
        flags.append("No validation result")

    # Claims runtime validation without evidence
    runtime_claim = re.search(
        r"(?i)(runtime\s+validated|level\s*:\s*3|validation\s+level\s*:\s*3)", text
    )
    runtime_evidence = re.search(
        r"(?i)(smoke_project|run_project|ran\s+the\s+game|opened\s+in\s+godot|headless\s+boot|actually\s+ran|ran\s+smoke)", text
    )
    if runtime_claim and not runtime_evidence:
        flags.append("Claims runtime validation (level 3) without run/open/playtest evidence")

    # Claims playtest validation without human notes
    playtest_claim = re.search(
        r"(?i)(playtest\s+validated|level\s*:\s*4|validation\s+level\s*:\s*4)", text
    )
    playtest_evidence = re.search(
        r"(?i)(human\s+playtest|manual\s+playtest|player\s+notes|feel|playability|input\s+device)", text
    )
    if playtest_claim and not playtest_evidence:
        flags.append("Claims playtest validation (level 4) without human playtest notes")

    # Broad claims from narrow inspection
    broad_claim = re.search(r"(?i)(system\s+is\s+working|fully\s+functional|all\s+systems|everything\s+works)", text)
    if broad_claim:
        files_m = re.search(r"(?i)Files\s+inspected\s*:(.*?)(?=\nFiles\s+changed|\Z)", text, re.DOTALL)
        if files_m:
            file_count = len([l for l in files_m.group(1).split("\n") if l.strip().startswith("-")])
            if file_count <= 2:
                flags.append("Broad repo claim ('system is working') from narrow inspection (<=2 files)")

    # Recommends large rewrite
    if re.search(r"(?i)(rewrite\s+everything|full\s+rewrite|refactor\s+the\s+whole|overhaul\s+the\s+entire)", text):
        flags.append("Recommends large rewrite without scoped evidence")

    # Changed gameplay during docs-only task
    task_m = re.search(r"(?i)Task\s*(?:type)?\s*:\s*(.+)", text)
    if task_m:
        task_val = task_m.group(1).lower()
        if "doc" in task_val or "arch" in task_val or "tooling" in task_val:
            changed_m = re.search(r"(?i)Files\s+changed\s*:(.*?)(?=\n[A-Z]|\Z)", text, re.DOTALL)
            if changed_m:
                changed_block = changed_m.group(1).lower()
                gameplay_patterns = [".gd", "scenes/", "project.godot", "data/"]
                if any(p in changed_block for p in gameplay_patterns):
                    flags.append("Changed gameplay/scene files during docs-only or tooling task")

    # Claims PASS but validation missing
    if re.search(r"(?i)Score\s*:\s*PASS", text):
        if not re.search(r"(?i)Validation\s+result\s*:\s*(passed|pass|ok)", text):
            flags.append("Claims PASS but validation result is missing or unclear")

    # No recommended next step
    if not re.search(r"(?i)(Recommended\s+next\s+step|What\s+should\s+happen\s+next)\s*:\s*\S", text):
        flags.append("No recommended next step")

    # More than one recommended next step (multiple bullet items)
    ns_m = re.search(
        r"(?i)(Recommended\s+next\s+step|What\s+should\s+happen\s+next)\s*:(.*?)(?=\n[A-Z][A-Z]|\Z)",
        text, re.DOTALL
    )
    if ns_m:
        steps = [l for l in ns_m.group(2).split("\n") if l.strip().startswith("-")]
        if len(steps) > 1:
            flags.append(f"More than one recommended next step ({len(steps)} found — should be exactly one)")

    # Mixes Lockbox/game-design into confirmed repo truth
    truth_m = re.search(
        r"(?i)Confirmed\s+repo\s+truth\s*:(.*?)(?=\nUnverified|\Z)", text, re.DOTALL
    )
    if truth_m:
        truth_block = truth_m.group(1).lower()
        lockbox_words = ["lockbox", "game design", "design direction", "future plan", "roadmap", "proposed", "should add", "will add"]
        found_lockbox = [w for w in lockbox_words if w in truth_block]
        if found_lockbox:
            flags.append(f"Confirmed repo truth mixes Lockbox/game-design speculation: {found_lockbox}")

    # No stale-truth warning for fragile system mentions (outside of the stale-truth block)
    for sys_name in FRAGILE_SYSTEMS:
        if sys_name.lower() in tl:
            if not re.search(r"(?i)(stale.truth|fragile|fresh\s+audit|caution|warning)", text):
                flags.append(f"Mentions fragile system '{sys_name}' without stale-truth warning")
                break  # one notice is enough

    return flags


def detect_stale_truth_warnings(text):
    warnings = []
    tl = text.lower()
    for sys_name in FRAGILE_SYSTEMS:
        if sys_name.lower() in tl:
            # Check if change is recommended
            changed_m = re.search(r"(?i)Files\s+changed\s*:(.*?)(?=\n[A-Z]|\Z)", text, re.DOTALL)
            recommend_m = re.search(
                r"(?i)(Recommended\s+next\s+step|What\s+should\s+happen\s+next)\s*:(.*?)(?=\n[A-Z][A-Z]|\Z)",
                text, re.DOTALL
            )
            changed_block = changed_m.group(1).lower() if changed_m else ""
            recommend_block = recommend_m.group(2).lower() if recommend_m else ""

            touches_it = sys_name.lower() in changed_block or sys_name.lower() in recommend_block
            has_audit = re.search(r"(?i)(fresh\s+audit|runtime\s+validation|playtest|smoke_project|run_project)", text)
            if touches_it and not has_audit:
                warnings.append(
                    f"  - '{sys_name}' touched or recommended without fresh audit/runtime validation"
                )
    return warnings


def score(fields_present, red_flags, stale_warnings, text):
    missing_core = [k for k, v in fields_present.items() if not v and k in (
        "agent", "task_type", "files_inspected", "files_changed",
        "validation_run", "validation_result", "confirmed_truth", "next_step"
    )]

    severe_flags = [
        f for f in red_flags if any(kw in f.lower() for kw in [
            "no files inspected listed",
            "no validation run reported",
            "no validation result",
            "no recommended next step",
            "claims runtime validation",
            "claims playtest validation",
            "changed gameplay",
            "large rewrite",
            "mixes lockbox",
            "broad repo claim",
        ])
    ]

    if missing_core or severe_flags:
        return "FAIL"

    minor_issues = [f for f in red_flags if f not in severe_flags]
    if minor_issues or stale_warnings or not fields_present.get("branch_commit") or not fields_present.get("validation_level"):
        return "WARN"

    return "PASS"


def final_recommendation(score_val, red_flags, stale_warnings):
    if score_val == "PASS":
        return "ACCEPT AS CURRENT REPO TRUTH"

    runtime_flag = any("runtime" in f.lower() or "playtest" in f.lower() for f in red_flags)
    stale_flag = bool(stale_warnings)
    fail_core = any(kw in " ".join(red_flags).lower() for kw in [
        "no files inspected", "no validation run", "no validation result",
        "claims runtime validation", "claims playtest", "mixes lockbox", "large rewrite"
    ])

    if score_val == "FAIL":
        if stale_flag:
            return "ROUTE TO GEMINI FOR FRESH AUDIT"
        if runtime_flag:
            return "ROUTE TO HUMAN PLAYTEST"
        return "REJECT / REQUEST REWORK"

    if score_val == "WARN":
        if stale_flag:
            return "ROUTE TO GEMINI FOR FRESH AUDIT"
        return "ACCEPT WITH WARNINGS"

    return "ACCEPT WITH WARNINGS"


def format_fields(fields_present):
    lines = []
    for key, label in FIELD_LABELS.items():
        status = "PRESENT" if fields_present.get(key) else "MISSING"
        lines.append(f"  {label:<28} {status}")
    return "\n".join(lines)


def main():
    text = load_report(sys.argv)
    fields_present = check_required_fields(text)
    red_flags = detect_red_flags(text)
    stale_warnings = detect_stale_truth_warnings(text)
    val_level = detect_validation_level(text)
    score_val = score(fields_present, red_flags, stale_warnings, text)
    recommendation = final_recommendation(score_val, red_flags, stale_warnings)

    out = []
    out.append("# AGENT REPORT SCORE")
    out.append("")
    out.append("## Score")
    out.append(score_val)
    out.append("")
    out.append("## Validation Level Detected")
    out.append(val_level)
    out.append("")
    out.append("## Required Fields")
    out.append(format_fields(fields_present))
    out.append("")
    out.append("## Red Flags")
    if red_flags:
        for f in red_flags:
            out.append(f"  - {f}")
    else:
        out.append("  None")
    out.append("")
    out.append("## Stale Truth Warning")
    if stale_warnings:
        for w in stale_warnings:
            out.append(w)
    else:
        out.append("  None")
    out.append("")
    out.append("## Final Recommendation")
    out.append(recommendation)
    out.append("")

    print("\n".join(out))

    exit_code = {"PASS": 0, "WARN": 1, "FAIL": 2}.get(score_val, 2)
    sys.exit(exit_code)


if __name__ == "__main__":
    main()
