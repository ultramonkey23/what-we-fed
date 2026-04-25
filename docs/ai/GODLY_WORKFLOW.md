# GODLY v2.3 — AUTONOMOUS MEDIUM EVOLUTION ENGINE

## Purpose
GODLY v2.3 lets agents make autonomous micro, semi-micro, and medium-level improvements inside explicit operating bounds.

It is designed for:
- autonomous micro-upgrades
- semi-micro gameplay evolution
- medium-level bounded game/combat improvements
- combat readability upgrades
- HUD/UI flow improvements
- data/system tuning
- isolated helper/presenter extraction
- controlled multi-agent improvement passes

GODLY means: Goal → Operating Bounds → Delegation → Leverage Picks → Yield Validation.

## Core Doctrine
Autonomy is allowed.
Unboundedness is not.
Meaningful change. Bounded blast radius. Evidence-backed validation.
The user provides the arena.
The agent chooses the best fight.
Medium changes are allowed.
Unbounded refactors are not.
Every changed system must interlock, audit cleanly, validate, and remain future-proof.

## Install vs Run Distinction
Installing/upgrading GODLY is docs/tools only.
Running GODLY may allow gameplay/combat edits if the manifest explicitly permits them.

A GODLY install must not edit gameplay code, scenes, project.godot, input maps, combat systems, or Lockbox card content. Those are reserved for GODLY runs whose manifest explicitly permits them.

---

## When To Use
Use when the user explicitly asks for:
- godly workflow
- agent gauntlet
- autonomous micro-upgrades
- semi-micro gameplay evolution
- medium-level bounded combat or system evolution
- bounded combat improvement
- vibe pass
- cleanup sprint
- controlled multi-agent improvement pass

Do not use for:
- full combat rewrites
- major refactors
- broad gameplay redesign
- Lockbox status promotion
- production-critical changes without fresh repo truth
- tasks with unclear validation

---

## Autonomous Decision Rights
Within the manifest, agents may autonomously decide:
- which allowed files to inspect
- which candidate tasks are highest leverage
- which proposals to reject
- which accepted tasks to implement
- whether a small connector patch is needed
- whether a small hardening patch is needed
- whether validation requires manual playtest
- whether the result is commit-ready
- whether to stop early because risk is too high
- whether a medium change should be downgraded into a safer slice
- whether fewer than the maximum allowed tasks should be selected

Agents may not autonomously decide:
- to exceed max task/file/line budgets
- to touch protected files without manifest permission
- to modify project.godot without explicit permission
- to modify scene files without explicit permission
- to change Lockbox status
- to promote repo truth without evidence
- to perform broad refactors
- to rewrite combat architecture
- to remove lanes wholesale
- to combine extraction, behavior tuning, UI changes, and reward-flow changes in one GODLY task unless explicitly allowed
- to claim runtime/playtest success without evidence
- to commit after failed validation
- to hide risk or uncertainty

---

## Required Manifest
Every GODLY run must declare:
- goal
- mode
- evolution tier
- max tasks
- max changed files
- max line-change soft cap
- max line-change hard cap
- allowed paths
- forbidden paths
- protected files
- commit allowed yes/no
- gameplay files allowed yes/no
- combat files allowed yes/no
- scene files allowed yes/no
- project.godot allowed yes/no
- Lockbox changes allowed yes/no
- status promotion allowed yes/no
- validation required
- manual playtest trigger
- rollback plan

---

## Evolution Tiers

### micro
Tiny local improvement.
Default:
- max tasks: 3
- max changed files: 4
- line soft cap: 150

Examples:
- copy refinement
- docstring
- small flavor data field
- small docs correction

### semi-micro
Meaningful bounded gameplay or systems improvement.
Default:
- max tasks: 2
- max changed files: 4
- line soft cap: 250

Examples:
- combat feedback improvement
- enemy readability adjustment
- HUD feedback tuning
- creature data tuning
- reward feedback improvement
- small rhythm feedback adjustment

### medium
Medium-level bounded game/system evolution.
Default:
- max tasks: 3
- max changed files: 8
- line soft cap: 700
- line hard cap: 1200

Examples:
- one isolated helper/presenter extraction
- one bounded HUD flow improvement
- one combat readability pass
- one reward presentation improvement
- one creature support/data integration improvement
- one validation-backed gameplay feedback improvement
- one medium data/system tuning pass

Medium does NOT mean:
- full subsystem rewrite
- broad architecture migration
- unrestricted CombatScene refactor
- multiple Lockbox cards at once
- protected file changes without manifest permission

### slice
One isolated extraction or modularization step.
Default:
- max tasks: 1
- max changed files: 6
- line soft cap: 500

Examples:
- create presenter/helper shell
- move one bounded responsibility
- extract one small service from a monolith
- no behavior change unless explicitly allowed

### sprintlet
Two or three related bounded changes under strict budget.
Default:
- max tasks: 3
- max changed files: 8
- line soft cap: 900
- line hard cap: 1400

Requires:
- stronger validation
- rollback plan
- Firmware Yield Gate
- report scoring

### audit-only
No edits. Inspect, map, and propose.

---

## Modes

### proposal-only
No edits. Agents only propose ranked tasks.

### docs-only
May edit docs/ai and repo-control docs only.

### vibe-pass
May edit text, labels, flavor, UI copy, and data flavor fields.
No gameplay logic changes unless explicitly allowed.

### micro-code
Tiny safe code/data/doc changes.
Default max tasks: 3.
Default max files: 4.

### semi-micro-gameplay
Meaningful bounded gameplay/combat evolution.
Default max tasks: 2.
Default max files: 4.
Default line-change soft cap: 250.
Requires manual playtest if feel, input, rhythm, readability, or combat feedback changes.

### medium-evolution
Medium-level bounded game/combat/system evolution.

Default manifest:
- max tasks: 3
- max changed files: 8
- line soft cap: 700
- line hard cap: 1200
- gameplay files allowed: true
- combat files allowed: true
- scene files allowed: explicit-only
- project.godot allowed: false unless explicit
- Lockbox changes allowed: false
- status promotion allowed: false
- commit allowed: false by default

Medium-evolution defaults to report-only.
Commit requires explicit manifest permission and should usually happen only after user review of the GODLY report.

Required:
- validation commands
- rollback plan
- Firmware Yield Gate
- manual playtest caveat if feel/readability/input/rhythm changes

### slice-prep
Prepares a future extraction without moving major behavior.
Useful before CombatScene modularization.

### validation-fix
Fix validation scripts or broken checks only.

### autonomous-sprint
Multiple bounded tasks under strict budget.
Requires explicit user approval.

### emergency-fix
Only for restoring build/validation.
No feature work.

---

## Blast Radius Classes
Define:
- Low: docs/ai, tools/ai, examples
- Medium-low: data-only flavor or tuning with validation
- Medium: UI style scripts, labels, feedback text
- Medium-high: bounded gameplay scripts
- High: CombatScene.gd, scene files, autoloads, save/state systems
- Protected: project.godot, input map, broad scene changes, Lockbox statuses

Protected files require explicit manifest permission.

---

## High-Risk File Rules

### CombatScene.gd
May be touched only if explicitly allowed in the manifest.

If touched:
- max lines changed without slicing audit: 120
- must include changed-system map
- must include rollback plan
- must run validation
- must pass SYMBIOTE Firmware Interlock
- must pass BUILD DOCTOR Final Validation
- must not become broad refactor unless user explicitly requested refactor
- must not combine extraction, behavior tuning, UI changes, and reward-flow changes in the same GODLY task unless the manifest explicitly allows that combination

### project.godot
Protected.
Changing it requires explicit permission and must be isolated from unrelated work.

### Scene Files
Protected by default.
Changing them requires explicit permission and runtime validation when practical.

### Autoloads / Save State
High risk.
Changing them requires manifest permission and stronger validation.

---

## Specialist Roles

Each specialist may propose one task:
- BRAIN: highest-leverage strategy
- SURGEON: safe code improvement
- CYBORG: repo consistency / truth protection
- SYMBIOTE: identity and system interlock
- VIBE-CODER: labels, juice, flavor, feel
- BUILD DOCTOR: validation / durability
- VISUAL INSPECTOR: readability / contrast / UI clarity
- ALFRED: coordination / report / next move

---

## Agent Council Enforcement

A GODLY run must not collapse specialist roles into one generic assistant voice.

Before implementation, the GODLY Orchestrator must run an Agent Council.

Required seats:
- BRAIN
- SURGEON
- CYBORG
- SYMBIOTE
- VIBE-CODER
- BUILD DOCTOR
- VISUAL INSPECTOR
- ALFRED

Each required seat must either propose one task or abstain with a reason.

No implementation may begin until every required seat has spoken.

Each council entry must include:
- Agent Seat
- Proposed task or ABSTAIN
- Target files
- Expected value
- Risk
- Validation required
- Manifest fit
- Verdict: Proceed / Reject / Abstain
- Reason

After the Agent Council, the Orchestrator must score all proposals and choose Selected Leverage Picks.

Implementation may only touch Selected Leverage Picks.

A GODLY run is invalid if:
- Agent Council is missing
- any required agent seat is missing
- any required seat neither proposes nor abstains
- Orchestrator Selection is missing
- Selected Leverage Picks are missing
- implementation includes work not selected by the Orchestrator

Required report sections:

## Agent Council

### BRAIN
Agent Seat:
Proposed task or ABSTAIN:
Target files:
Expected value:
Risk:
Validation required:
Manifest fit:
Verdict:
Reason:

### SURGEON
Agent Seat:
Proposed task or ABSTAIN:
Target files:
Expected value:
Risk:
Validation required:
Manifest fit:
Verdict:
Reason:

### CYBORG
Agent Seat:
Proposed task or ABSTAIN:
Target files:
Expected value:
Risk:
Validation required:
Manifest fit:
Verdict:
Reason:

### SYMBIOTE
Agent Seat:
Proposed task or ABSTAIN:
Target files:
Expected value:
Risk:
Validation required:
Manifest fit:
Verdict:
Reason:

### VIBE-CODER
Agent Seat:
Proposed task or ABSTAIN:
Target files:
Expected value:
Risk:
Validation required:
Manifest fit:
Verdict:
Reason:

### BUILD DOCTOR
Agent Seat:
Proposed task or ABSTAIN:
Target files:
Expected value:
Risk:
Validation required:
Manifest fit:
Verdict:
Reason:

### VISUAL INSPECTOR
Agent Seat:
Proposed task or ABSTAIN:
Target files:
Expected value:
Risk:
Validation required:
Manifest fit:
Verdict:
Reason:

### ALFRED
Agent Seat:
Proposed task or ABSTAIN:
Target files:
Expected value:
Risk:
Validation required:
Manifest fit:
Verdict:
Reason:

## Orchestrator Selection

| Agent | Proposal | Value 0-5 | Risk 0-5 | Reversibility 0-5 | Validation Clarity 0-5 | Game Value 0-5 | Manifest Fit | Decision | Reason |
|---|---|---:|---:|---:|---:|---:|---|---|---|

## Selected Leverage Picks

Only these selected tasks may be implemented.

---

## Proposal Scoring

Score each proposal:

| Proposal | Value 0-5 | Risk 0-5 | Reversibility 0-5 | Validation Clarity 0-5 | Token Cost 0-5 | Game Value 0-5 | Blast Radius | Decision |
|---|---:|---:|---:|---:|---:|---:|---|---|

Selection priority:
1. high game value
2. low risk
3. high reversibility
4. clear validation
5. manageable blast radius
6. reasonable token cost

The agent should reject:
- vague tasks
- broad refactors
- tasks with unclear validation
- tasks outside allowed paths
- tasks that exceed budget
- tasks that require protected files without permission
- tasks that need playtest but cannot provide a playtest caveat

---

## Autonomous Leverage Picks
After scoring, the agent may choose the best tasks without asking the user, as long as:
- task count stays within budget
- file count stays within budget
- line budget is respected or justified
- protected files remain untouched unless allowed
- validation is available
- rollback path is clear

The agent may choose fewer than the maximum tasks if fewer high-quality tasks exist.

---

## Stop-Early Authority
The agent must stop early if:
- no safe high-value task exists
- repo truth is stale for the target area
- validation cannot be run
- all useful tasks exceed the manifest
- the only attractive tasks require protected files
- implementation would become a broad refactor
- the change requires human playtest before safe continuation

Stopping early with a useful report is considered a successful GODLY run.

---

## Required Workflow Order

Manifest Intake
→ Autonomous Scan Inside Allowed Zones
→ Agent Council
→ Orchestrator Selection
→ Selected Leverage Picks
→ Implementation
→ Local Validation
→ SYMBIOTE Firmware Interlock
→ Optional SYMBIOTE Connector Patch
→ CYBORG Scope / Truth Audit
→ BUILD DOCTOR Future-Proofing + Final Validation
→ Optional BUILD DOCTOR Hardening Patch
→ Report Scoring
→ Commit Decision

---

## Firmware Yield Gate

The Firmware Yield Gate is the three-stage interlock that guards every commit decision: SYMBIOTE Firmware Interlock, then CYBORG Scope / Truth Audit, then BUILD DOCTOR Future-Proofing + Final Validation. All three must reach PASS or accepted WARN before the run is commit-eligible.

### SYMBIOTE Firmware Interlock

SYMBIOTE verifies changed systems logically interlock with each other and with the repo.

Required checks:
- changed-system map
- signal interlock
- data-shape interlock
- UI/text interlock
- runtime truth interlock
- validation interlock
- blast-radius interlock

Required report table:

| Changed System | Upstream Dependencies | Downstream Effects | Interlock Status | Evidence | Required Follow-up |
|---|---|---|---|---|---|

Final Interlock Verdict:
PASS / WARN / PATCH REQUIRED / FAIL

#### SYMBIOTE Connector Patch Budget
After implementation and local validation, SYMBIOTE may make one small interlock patch if required.

Budget:
- max tasks: 1
- max files: 2
- max lines: 100

Allowed:
- connector fix
- doc caveat correction
- naming consistency
- data-shape compatibility
- report truth correction
- small UI text consistency fix

Forbidden:
- new feature
- broad refactor
- CombatScene rewrite
- project.godot
- Lockbox status changes
- new architecture

### CYBORG Scope / Truth Audit

CYBORG verifies manifest compliance and truth discipline.

Required checks:
- manifest compliance
- files changed vs allowed paths
- protected files untouched unless allowed
- no Lockbox status promotion
- no unverified runtime claims
- no scope expansion
- no hidden second objective
- accurate validation level

Required report table:

| Area | Status | Evidence | Follow-up |
|---|---|---|---|
| Manifest Compliance | PASS/WARN/FAIL |  |  |
| Repo Truth Discipline | PASS/WARN/FAIL |  |  |
| Protected Files | PASS/WARN/FAIL |  |  |
| Scope Control | PASS/WARN/FAIL |  |  |
| Validation Level Accuracy | PASS/WARN/FAIL |  |  |

Final CYBORG Verdict:
PASS / WARN / PATCH REQUIRED / FAIL

### BUILD DOCTOR Future-Proofing + Final Validation

BUILD DOCTOR verifies durability and commit readiness.

Required checks:
- build health
- regression risk
- future-proofing
- dependency durability
- commit readiness
- rollback clarity

Required report table:

| Area | Status | Evidence | Follow-up |
|---|---|---|---|
| Build Health | PASS/WARN/FAIL |  |  |
| Regression Risk | PASS/WARN/FAIL |  |  |
| Future-Proofing | PASS/WARN/FAIL |  |  |
| Dependency Durability | PASS/WARN/FAIL |  |  |
| Commit Readiness | PASS/WARN/FAIL |  |  |

Final Build Doctor Verdict:
PASS / WARN / PATCH REQUIRED / FAIL

#### BUILD DOCTOR Hardening Patch Budget
After CYBORG scope/truth audit, BUILD DOCTOR may make one small durability patch if required.

Budget:
- max tasks: 1
- max files: 3
- max lines: 180

Allowed:
- validation script update
- fixture update
- missing default value
- data compatibility guard
- docs validation caveat
- small error-message improvement
- CI/local check alignment

Forbidden:
- new gameplay feature
- combat design change
- broad refactor
- project.godot unless explicitly allowed
- Lockbox status changes
- aesthetic/vibe changes

---

## Validation Tier Matching
Docs/tooling changes require static/tool validation.
Data changes require data validation.
UI/readability changes require project validation and may require screenshot or manual review.
Combat feel changes require project validation, smoke validation, and human playtest.
Input/rhythm changes require project validation, smoke validation, and human playtest.
Scene/project settings changes require explicit permission and runtime validation.

---

## Manual Playtest Trigger
Manual playtest is required if a GODLY run changes:
- combat feel
- input feel
- rhythm timing or beat feel
- readability
- UI/HUD feedback
- enemy threat clarity
- player-facing feedback

---

## Commit Rule

A GODLY run may commit only if:
- commit_allowed is true in the manifest
- SYMBIOTE is PASS or accepted WARN
- CYBORG is PASS or accepted WARN
- BUILD DOCTOR is PASS or accepted WARN
- report scoring passes or accepted WARN is documented
- validation failures are not ignored
- protected files are not staged unless explicitly allowed
- final changed files fit the manifest
- manual playtest requirements are satisfied or clearly listed as follow-up

If commit_allowed is false, the run must stop with a commit-ready report only.

---

## Signal Map Integration

If a GODLY run changes EventBus signal declarations, signal emitters, signal consumers, or signal payload shape:
- regenerate `docs/ai/SIGNAL_MAP.md` by running from the `what-we-fed/` directory: `python ../tools/ai/generate_signal_map.py`
- SYMBIOTE Firmware Interlock must consult the signal map before passing signal interlock
- CYBORG must check signal-truth claims against source and verify no undeclared references
- BUILD DOCTOR must verify the map was regenerated (or document why it was not)

---

## Required GODLY Report
Every GODLY run must output:
- manifest used
- autonomous scan summary
- Agent Council
- Orchestrator Selection
- Selected Leverage Picks
- accepted tasks
- rejected tasks
- files changed
- validation run
- SYMBIOTE Firmware Interlock
- CYBORG Scope / Truth Audit
- BUILD DOCTOR Future-Proofing + Final Validation
- manual playtest requirement
- report score or validation
- commit decision
- risks
- recommended next step
- WHAT WE FED AGENT REPORT
