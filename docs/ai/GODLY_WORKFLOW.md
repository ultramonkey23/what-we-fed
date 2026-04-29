# GODLY v2.5 — SOVEREIGN EVOLUTION ENGINE

## Purpose
GODLY v2.5 is the autonomous evolution engine for WHAT WE FED. It empowers agents to make meaningful improvements while strictly enforcing the **Sovereign Core (v2.7)** protocols.

## Core Pillars
All GODLY runs are governed by:
1. **[SOVEREIGN_CORE.md](SOVEREIGN_CORE.md)**: Authority Order, 5 Laws, Validation Ladder.
2. **[ARCHETYPES.md](ARCHETYPES.md)**: Agent roles and lead lanes.
3. **[REPO_TRUTH_PROTOCOL.md](REPO_TRUTH_PROTOCOL.md)**: Stale-truth rules and ledger discipline.
4. **[REPORT_CONTRACT.md](REPORT_CONTRACT.md)**: The Auditor's Report (v2.5) standard.

---

## Workflow: The Extraction Loop

### 1. Manifest Intake
Every run begins with a user-approved **GODLY Manifest**:
- **Goal**: [Description]
- **Tier**: micro | semi-micro | medium | sprintlet
- **Allowed Paths**: [Glob Patterns]
- **Forbidden Paths**: [Glob Patterns]
- **Budgets**: Max Tasks | Max Files | Line Cap
- **Commit Allowed**: Yes/No

### 2. The Agent Council
Before implementation, the lead agent (usually BRAIN or CYBORG) convenes the council. 
- **Required Seats**: SIGNAL, BRAIN, AUDITOR, SURGEON, VISUALS, VOID, SCOUT.
- **Output**: A list of **Selected Leverage Picks** (Ranked tasks).
- **Rule**: Each pick must map to a lead lane.

### 3. Sequential Mutation
Implementation follows Sovereign Law 3:
- One bounded move at a time.
- No parallel edits to the same file.
- Strict assumption-busting (Layer 2 verification) before every edit.

### 4. Micro-Validation
Following Sovereign Law 4:
- Run `validate_project.bat` or `smoke_project.bat` incrementally.
- Map evidence to the **Validation Ladder (0-4)**.
- **Tier 3 (Runtime)** is mandatory for gameplay logic.
- **Tier 4 (Playtest)** is mandatory for feel/readability.

### 5. Extraction Report
Conclude with the **Auditor's Report (v2.5)** as defined in `REPORT_CONTRACT.md`. 

---

## Operating Budgets

| Tier | Max Tasks | Max Files | Line Cap | Examples |
|---|---|---|---|---|
| **micro** | 3 | 4 | 150 | Copy, small data tuning, docs. |
| **semi-micro** | 2 | 4 | 250 | Feedback, enemy readability, HUD. |
| **medium** | 3 | 8 | 1200 | Helper extraction, combat flow, data systems. |
| **sprintlet** | 3 | 8 | 1400 | Multi-agent improvement pass. |

---

## High-Risk Guardrails
- **CombatScene.gd**: Protected. Changes must be sliced and include a rollback plan.
- **project.godot**: Protected. Requires explicit user approval per edit.
- **DNA Economy**: Protected. Must pass GROWTH-AUDITOR review.
- **Timing Truth**: Protected. Any change to frame-rate or delta logic is a high-risk escalation.

## Signal Map Policy
If signals change:
1. Regenerate `docs/ai/SIGNAL_MAP.md` using `tools/ai/generate_signal_map.py`.
2. Verify all listeners/emitters in `REPO_TRUTH_PROTOCOL.md`.
