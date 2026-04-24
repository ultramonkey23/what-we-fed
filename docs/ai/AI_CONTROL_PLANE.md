# AI CONTROL PLANE
Version: 1.0 | Complements: MULTI_AI_OPERATING_LAYER.md, AGENTS.md, SYSTEM_KERNEL.md

## Purpose
This file defines how AI agents work inside the WHAT WE FED repo without drifting, inventing repo truth, duplicating systems, or making unsafe changes.

## Separation Of Duties
- **Command Center v1** handles Lockbox/game-design task management.
- **Repo agents** handle inspected repo work only.
- **This AI Control Plane** handles agent routing, prompt quality, report quality, validation discipline, and stale-truth prevention.
- Do not mix Lockbox/game-design speculation into confirmed repo truth.

## Core Rules
1. Inspect before editing.
2. Prefer small safe changes.
3. Preserve working systems.
4. Separate build-now from build-later.
5. Never claim runtime validation unless the project was actually run or playtested.
6. Never treat design direction as implemented repo truth.
7. No broad refactors without a fresh audit and explicit approval.
8. Every implementation must end with an agent report.

---

## Agent Lanes

| Task Type | Best Agent | Reason |
|---|---|---|
| Repo scan / architecture diagnosis | Gemini (SYMBIOTE) | broad inspection, large-context synthesis, system mapping |
| Strategic design / architecture options | Gemini or Claude (BRAIN) | reasoning before edits |
| Complex multi-file implementation | Claude (ALFRED) | careful editing and integration |
| Bounded bug fix / cleanup / validation | Codex (CYBORG) | contained changes, testable scope |
| Live small targeted edits | Cursor (ALFRED) | fast local iteration |
| Visual / HUD readability judgment | Claude + screenshots (INSPECTOR) | visual evidence required |
| Manual playtest | Human | real feel and runtime truth |

Full specialist map: `AGENTS.md` → The Specialist Squad.

---

## Fresh Truth Gate
Before implementation, at least one of these must exist:
- Fresh agent report (within this session or linked)
- Changed files list from git
- Inspected files list from current session
- Test/validation output (`smoke_project.bat`, `validate_data.bat`, etc.)
- Godot run output or error log
- Screenshot or video evidence
- Manual playtest notes

**If none exist → route to Gemini for fresh repo audit before proceeding.**

---

## Stale Truth Rule
Repo truth is stale when any of the following apply:
- A major implementation happened after the latest report.
- Multiple reports conflict.
- The user is unsure what changed.
- Runtime behavior differs from documentation.
- The task touches fragile systems:
  - `CombatScene.gd`
  - `PlayerCombat.gd`
  - `LaneManager.gd`
  - `GameState.gd`
  - `SongConductor.gd`
  - `CombatContent.gd`

**If stale → do not implement. Request or generate a fresh audit prompt.**

---

## Implementation Boundaries
Before starting, every agent must state:
- Files they will **inspect**
- Files they **expect to change**
- Systems they will **not touch**
- Validation they will **run**

---

## Validation Ladder

| Level | Name | Evidence Required |
|---|---|---|
| 0 | Not validated | Idea only; no repo inspection |
| 1 | Inspected | Files read; no run/test |
| 2 | Static validated | Syntax/static/grep checks; no runtime |
| 3 | Runtime validated | Project opens/runs; relevant scene exercised |
| 4 | Playtest validated | Human manual playtest confirms feel, readability, and intended behavior |

Claim only the level actually achieved. "Static validated" is honest and acceptable. "Runtime validated" without a run is false.

---

## Required Agent Report
Every agent must end with this block:

```
WHAT WE FED AGENT REPORT
Agent:
Date:
Branch/commit if available:
Task type:
Files inspected:
Files changed:
Validation run:
Validation level: (0–4)
Validation result:
Confirmed repo truth:
Unverified assumptions:
Recommended next step:
Risks:
```

Full report template: `docs/agent_reports/REPORT_TEMPLATE.md`

---

## Prompt Quality Checklist
Before sending any implementation prompt, verify:
- [ ] Task is one bounded objective
- [ ] Repo truth source is named
- [ ] Files/systems to avoid are named
- [ ] Validation is explicit
- [ ] Output format requires an agent report
- [ ] No "rewrite everything" language
- [ ] No Lockbox/game-design speculation treated as implemented truth

Full prompt templates: `docs/ai/PROMPT_CONTRACTS.md`

---

## Escalation Rules
| Situation | Action |
|---|---|
| Repo truth is missing or stale | Escalate to Gemini for fresh audit |
| Implementation crosses multiple systems | Escalate to Claude (ALFRED/BRAIN) |
| Fix is narrow and statically testable | Escalate to Codex (CYBORG) |
| Question is feel, rhythm, readability, or fun | Escalate to human playtest |
| Visual/HUD judgment needed | Escalate to INSPECTOR with screenshot evidence |

---

## Report Scoring — Validation Discipline
Before any agent report is accepted as repo truth, score it:

```
python tools/ai/score_agent_report.py path/to/report.txt
```

- Scoring guide: `docs/ai/AGENT_REPORT_SCORECARD.md`
- Script: `tools/ai/score_agent_report.py`
- Examples: `docs/ai/examples/AGENT_REPORT_SCORE_EXAMPLE.md`

The scorer checks required fields, validation level honesty, stale-truth risk on fragile systems,
and routing problems. It does not replace human judgment — it catches mechanical gaps.

---

## Relation To Existing Docs
- `MULTI_AI_OPERATING_LAYER.md` — shared authority/lane contract (canonical)
- `SYSTEM_KERNEL.md` — full governance rules
- `AGENT_ROUTING_MATRIX.md` — quick lookup table (this layer)
- `REPORT_INGESTION_GATE.md` — report acceptance criteria (this layer)
- `PROMPT_CONTRACTS.md` — reusable prompt templates (this layer)
- `HUMAN_PLAYTEST_PROTOCOL.md` — playtest evidence format (this layer)
- `AGENT_REPORT_SCORECARD.md` — human-readable scoring guide (this layer)
- `tools/ai/score_agent_report.py` — automated report scorer (this layer)
