# AGENT REPORT SCORECARD
Reference for human reviewers. Mirrors the logic in `tools/ai/score_agent_report.py`.

---

## Purpose
Agent reports must be scored before their claims enter confirmed repo truth.
A report that is incomplete, overconfident about validation, or stale on fragile systems
can corrupt the repo's understanding of its own state and cause downstream failures.

---

## When To Score A Report
- After Gemini audits
- After Claude implementations
- After Codex fixes
- After Cursor edits
- Before updating repo truth or the Current Truth Snapshot
- Before using a report as implementation evidence
- Before routing a next step to another agent

---

## PASS / WARN / FAIL

**PASS** — All required fields present. Files inspected and changed are listed explicitly.
Validation run and result are specific. Confirmed repo truth is separated from assumptions.
Exactly one recommended next step. No severe red flags.
→ Promote confirmed truth; proceed to next step.

**WARN** — Mostly complete but has one or more of:
- Validation level is lower than what the task required (static check for runtime behavior)
- Assumptions are not clearly separated from confirmed truth
- Stale-truth risk exists but is disclosed
- Recommended next step is vague
- Minor overconfidence in wording
→ Accept with caveats. Note warnings in the ingestion summary.

**FAIL** — One or more severe problems:
- Missing core required fields
- No validation run or result
- Claims runtime or playtest validation without evidence
- Changes forbidden files (gameplay, scenes, project.godot) during a docs-only task
- Makes broad repo claims from a narrow inspection
- Recommends a large rewrite without scoped evidence
- Mixes Lockbox/game-design speculation into confirmed repo truth
→ Do not promote claims. Return for rework or route to Gemini for fresh audit.

---

## Required Fields

All reports must contain:

| Field | Notes |
|---|---|
| Agent | Tool name + repo-side specialist lane |
| Date | When the report was produced |
| Branch/commit | If available |
| Task type | One bounded objective |
| Files inspected | Explicit list — not "various files" |
| Files changed | Explicit list or "none" |
| Validation run | Command or method used; or "none" (be honest) |
| Validation level | 0–4 per Control Plane ladder |
| Validation result | Passed / failed / partial / unable |
| Confirmed repo truth | Only facts directly evidenced by inspection |
| Unverified assumptions | Anything not directly confirmed |
| Recommended next step | Exactly one |
| Risks | Any fragile, uncertain, or load-bearing concerns |

---

## Severe Red Flags

Each of these alone can cause a FAIL:

- No files inspected listed
- No files changed section (or it is a placeholder)
- No validation run reported
- No validation result
- Claims runtime validation (level 3) without run/open/playtest evidence
- Claims playtest validation (level 4) without human playtest notes
- Broad repo claim ("system is working", "everything works") from inspection of ≤2 files
- Recommends large rewrite without scoped evidence of breakdown
- Changed gameplay/scene files during a docs-only or tooling task
- No recommended next step
- More than one recommended next step
- Mixes Lockbox/game-design speculation into confirmed repo truth

Minor flags that together may produce WARN:
- Stale-truth risk exists but is disclosed
- Validation level is honest but lower than ideal for the task
- Recommended next step is present but vague
- Risk section is thin

---

## Stale Truth Triggers

If a report mentions or recommends editing any of these systems, require evidence of a fresh audit or runtime validation before accepting:

- `CombatScene.gd`
- `PlayerCombat.gd`
- `LaneManager.gd`
- `GameState.gd`
- `SongConductor.gd`
- `CombatContent.gd`
- `project.godot`

These are high-coupling, high-risk files. A report that modifies them and claims only static validation should be flagged WARN at minimum. A report that modifies them with no validation is FAIL.

---

## Validation Level Interpretation

| Level | Name | Evidence Required |
|---|---|---|
| 0 | Not validated | Idea only; no repo inspection |
| 1 | Inspected | Files read; no run or test |
| 2 | Static validated | Syntax/grep/static checks; no runtime |
| 3 | Runtime validated | Project opens/runs; relevant scene exercised |
| 4 | Playtest validated | Human manual playtest confirms feel, readability, and intended behavior |

Claim only the level actually achieved. "Static validated" is honest and acceptable.
"Runtime validated" without a run is false and triggers a red flag.

---

## What To Do After PASS
Accept confirmed truth. Add it to the Current Truth Snapshot if scope is appropriate.
Proceed to the one recommended next step.

## What To Do After WARN
Accept with caveats. Add confirmed truth with a caveat note.
Optionally request a narrow patch addressing the warning before proceeding.

## What To Do After FAIL
Do not promote any claims as repo truth.
Return the report for rework, or route to Gemini for a fresh audit.
If a fragile system is involved, require runtime validation before re-submission.

---

## Example Commands

```
python tools/ai/score_agent_report.py docs/agent_reports/example_report.txt

cat report.txt | python tools/ai/score_agent_report.py
```

The script process exits 0 (PASS), 1 (WARN), or 2 (FAIL) — usable in CI or shell pipelines.

## Local Validation

Run:

```bash
python tools/ai/validate_report_scorer.py
```

Expected:
- PASS fixture exits 0
- WARN fixture exits 1
- FAIL fixture exits 2

GitHub Actions also validates this contract in `.github/workflows/ai_report_scorer.yml`.

Fixture expectations:

```bash
python tools/ai/score_agent_report.py docs/ai/examples/_sample_report_pass.txt  # PASS, exit 0
python tools/ai/score_agent_report.py docs/ai/examples/_sample_report_warn.txt  # WARN, exit 1
python tools/ai/score_agent_report.py docs/ai/examples/_sample_report_fail.txt  # FAIL, exit 2
```
