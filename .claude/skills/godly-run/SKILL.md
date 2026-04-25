---
name: godly-run
description: Run GODLY v2.3 — bounded autonomous improvement within an explicit manifest. Use for micro-upgrades, semi-micro gameplay evolution, medium combat/system improvements, docs-only passes, and controlled multi-agent sprints.
allowed-tools: Read, Grep, Glob, Bash, Edit, Write
---

# GODLY Run

GODLY v2.3 — Autonomous Medium Evolution Engine.
Full spec: `docs/ai/GODLY_WORKFLOW.md`

## When To Use
- User asks for: godly workflow, agent gauntlet, autonomous upgrade, vibe pass, cleanup sprint, bounded improvement pass, mycelium upgrade.
- Do NOT use for: broad rewrites, major refactors, gameplay redesign, or tasks with unclear validation.

## Procedure

### Step 1 — Manifest Intake
Declare the manifest before touching any file:

```
goal:
mode: (docs-only | vibe-pass | micro-code | semi-micro-gameplay | medium-evolution | audit-only)
evolution tier: (micro | semi-micro | medium | slice | sprintlet | audit-only)
max tasks:
max changed files:
line soft cap:
line hard cap:
allowed paths:
forbidden paths:
protected files:
gameplay files allowed: yes/no
combat files allowed: yes/no
scene files allowed: yes/no
project.godot allowed: yes/no
commit allowed: yes/no
validation required:
rollback plan:
```

Default docs-only manifest (use when goal is AI system upgrade):
- mode: docs-only / tier: micro / max tasks: 3 / max files: 4 / line soft cap: 150
- allowed: `docs/ai/**`, `.claude/**`
- forbidden: `*.gd`, `*.tscn`, `project.godot`, `data/**`
- gameplay / combat / scene / project.godot allowed: no
- commit allowed: no

### Step 2 — Autonomous Scan Inside Allowed Zones
Read and map relevant files within allowed paths only. Do not open files outside the manifest. Identify candidate tasks ranked by leverage.

### Step 3 — Agent Council
Every GODLY run requires all eight seats. Each must either propose one task OR abstain with a reason. No seat may be skipped. No implementation begins until every seat has spoken.

Required seats:
- **BRAIN** — highest-leverage strategy
- **SURGEON** (ALFRED) — safe code improvement
- **CYBORG** — repo consistency / truth protection
- **SYMBIOTE** — identity and system interlock
- **VIBE-CODER** — labels, juice, flavor, feel
- **BUILD DOCTOR** — validation / durability
- **VISUAL INSPECTOR** — readability / contrast / UI clarity
- **ALFRED** — coordination / report / next move

Each council entry must include:
- Agent Seat / Proposed task or ABSTAIN / Target files / Expected value / Risk / Validation required / Manifest fit / Verdict / Reason

### Step 4 — Orchestrator Selection
Score all proposals using this table:

| Agent | Proposal | Value 0-5 | Risk 0-5 | Reversibility 0-5 | Validation Clarity 0-5 | Game Value 0-5 | Manifest Fit | Decision | Reason |
|---|---|---:|---:|---:|---:|---:|---|---|---|

Selection priority: high game value → low risk → high reversibility → clear validation → manageable blast radius.

Reject: vague tasks, broad refactors, tasks outside allowed paths, tasks exceeding budget, protected files without permission.

### Step 5 — Selected Leverage Picks
State exactly which tasks are selected. Only these may be implemented. No scope expansion.

### Step 6 — Implementation
Implement only selected picks. Respect manifest budgets on every file and line change. Stop early if a task would become a broad refactor or requires protected files.

### Step 7 — Local Validation
Run the appropriate command for the tier:
- docs/tooling changes: static review (read changed files, verify no broken refs)
- data changes: `validate_data.bat`
- code changes: `smoke_project.bat`
- combat feel changes: `run_project.bat` + manual playtest caveat

### Step 8 — Firmware Yield Gate (required for medium / sprintlet tiers)
Three sequential checks — all must reach PASS or accepted WARN:

**SYMBIOTE Firmware Interlock:**
Verify changed systems interlock with each other and the repo.
| Changed System | Upstream Dependencies | Downstream Effects | Interlock Status | Evidence | Required Follow-up |
|---|---|---|---|---|---|

**CYBORG Scope / Truth Audit:**
Verify manifest compliance and truth discipline.
| Area | Status | Evidence | Follow-up |
|---|---|---|---|
| Manifest Compliance | | | |
| Repo Truth Discipline | | | |
| Protected Files | | | |
| Scope Control | | | |
| Validation Level Accuracy | | | |

**BUILD DOCTOR Final Validation:**
Verify durability and commit readiness.
| Area | Status | Evidence | Follow-up |
|---|---|---|---|
| Build Health | | | |
| Regression Risk | | | |
| Future-Proofing | | | |
| Dependency Durability | | | |
| Commit Readiness | | | |

### Step 9 — Signal Map
If any EventBus signal declaration, emitter, consumer, or payload shape changed:
- Regenerate: `python tools/ai/generate_signal_map.py`
- SYMBIOTE must consult `docs/ai/SIGNAL_MAP.md` before passing signal interlock.

### Step 10 — GODLY Report + Commit Decision
Output the full GODLY report. If `commit_allowed: no` — stop here and present the report for user review.

A GODLY run may commit only if:
- commit_allowed is true in the manifest
- SYMBIOTE, CYBORG, and BUILD DOCTOR are all PASS or accepted WARN
- Validation failures are not ignored
- Protected files are not staged unless explicitly allowed

## Output Format
Every GODLY run must output:
- Manifest used
- Autonomous scan summary
- Agent Council (all 8 seats)
- Orchestrator Selection table
- Selected Leverage Picks
- Files changed
- Validation run and level
- Firmware Yield Gate results (if medium/sprintlet)
- Manual playtest requirement (if applicable)
- Commit decision
- Risks
- Recommended next step
- WHAT WE FED AGENT REPORT block

## Stop-Early Authority
Stop early (with a useful report) if:
- No safe high-value task exists within the manifest
- Repo truth is stale for the target area
- Validation cannot be run
- All useful tasks exceed the manifest
- Implementation would become a broad refactor
- Human playtest is required before safe continuation

Stopping early with a useful report is a successful GODLY run.
