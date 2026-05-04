---
name: score-report
description: Score a WHAT WE FED agent report for completeness, validation honesty, stale-truth risk, and routing problems. Runs tools/ai/score_agent_report.py. Use after any implementation task before accepting the result as repo truth.
allowed-tools: Bash, Read
---

# Score Report

Runs the automated agent report scorer before accepting a report as repo truth.
Tool: `tools/ai/score_agent_report.py`

## When To Use
- After any GODLY run, implementation task, or bug fix that produced an agent report.
- Before accepting a report as authoritative input for `docs/ai/CURRENT_PULSE.md` updates.
- When a report's validation level or scope feels uncertain.
- Required before commit in medium / sprintlet GODLY runs (Firmware Yield Gate).

## Procedure

### Step 1 — Locate the report
The report is either:
- Saved as a file in the repo (e.g., `docs/agent_reports/YYYY-MM-DD_task.txt`)
- Produced inline in session — save it to a temp file first

### Step 2 — Run the scorer
```bash
python tools/ai/score_agent_report.py path/to/report.txt
```
Or pipe from stdin:
```bash
cat report.txt | python tools/ai/score_agent_report.py
```

### Step 3 — Interpret results
The scorer checks:
- Required fields present (Agent, Date, Task type, Files inspected, Validation run, Validation level, Confirmed repo truth, Risks, Recommended next step)
- Validation level honesty (claimed level matches evidence — static-only cannot claim runtime)
- Stale-truth risk on fragile files (CombatScene.gd, PlayerCombat.gd, LaneManager.gd, GameState.gd, SongConductor.gd)
- Routing problems (wrong agent for the task type)

Exit codes:
- `0` → PASS: report is acceptable as repo truth
- `1` → WARN: report has gaps; document them before accepting
- `2` → FAIL: report must be revised; do not commit

### Step 4 — Act on result
- **PASS**: accept the report, proceed with commit decision
- **WARN**: document the specific gaps in follow-up notes before accepting
- **FAIL**: do not commit; revise the report or re-run the task with proper validation evidence

## Output
Return: scorer exit code, score result, specific flags raised, and decision (accepted / accepted-with-gaps / rejected).
