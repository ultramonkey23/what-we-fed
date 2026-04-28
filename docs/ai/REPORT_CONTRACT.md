# REPORTING CONTRACT
Every substantial agent intervention must conclude with a formal report.

## 1. THE AUDITOR'S REPORT (v2.5)
End every implementation turn with this block:

```md
## Auditor's Report (v2.5)
- **Task Type**: Inspect | Spec | Patch | Audit | Evolve
- **Blast Radius**: Tier 0 | 1 | 2 | 3
- **Evidence Type**: Runtime-Verified | Static-Only | Speculative
- **Self-Critique Results**:
  - [ ] Assumption-Busted (Verified Layer 2 Live Truth)
  - [ ] Identity Anchor Integrity (Timing/DNA/Beat-Feel)
  - [ ] Anti-Sludge (Combat-Clean/HUD-Minimal)
  - [ ] GDScript 2.0 Compliance (Typing/Signals/EventBus)
  - [ ] Signal Tracing (Emitted AND connected)
  - [ ] Null-Safety (@onready/%UniqueName verified)
- **Verified Facts**: [List specific confirmed implementation details]
- **Unverified Risks**: [List any remaining ambiguities or risks]
- **Next Bounded Move**: [The single most effective next action]
```

## 2. VALIDATION DISCIPLINE
- **Tier 1 (Inspected)**: Files read.
- **Tier 2 (Static)**: `validate_project.bat` or `tsc` or `ruff` passed.
- **Tier 3 (Runtime)**: Project ran, behavior exercised.
- **Tier 4 (Playtest)**: Manual verification of "feel."

## 3. REPORT SCORING
Automated scoring is available to catch mechanical gaps in reporting.
`python tools/ai/score_agent_report.py path/to/report.md`

- **Scoring Guide**: `docs/ai/REPORT_CONTRACT.md`
- **Template**: `agent_reports/REPORT_TEMPLATE.md`

## 4. HANDOFF FORMAT
When passing work to another agent:
- **Target File(s)**: [PATHS]
- **Working Truth**: [CONTEXT_LIMIT]
- **Bounded Goal**: [TASK_DESCRIPTION]
- **Validation Requirement**: [SPECIFIC_CHECK]
