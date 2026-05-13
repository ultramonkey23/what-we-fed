# REPORTING CONTRACT
Every substantial agent intervention must conclude with a formal report.

## 1. THE AUDITOR'S REPORT (v2.5)
End every implementation turn with this block:

```md
## Auditor's Report (v2.5)
- **Task Type**: Inspect | Spec | Patch | Audit | Evolve
- **Blast Radius**: Tier 0 | 1 | 2 | 3
- **Evidence Type**: Runtime-Verified | Static-Only | Speculative
- **Visual Proof**: [Path to _visual_proofs/task_folder/ or N/A]
- **Self-Critique Results**:
  - [ ] Assumption-Busted (Verified Layer 2 Live Truth)
  - [ ] Identity Anchor Integrity (Timing/DNA/Beat-Feel)
  - [ ] Anti-Sludge (Combat-Clean/HUD-Minimal)
  - [ ] GDScript 2.0 Compliance (Typing/Signals/EventBus)
  - [ ] Signal Tracing (Emitted AND connected)
  - [ ] Null-Safety (@onready/%UniqueName verified)
  - [ ] Visual Proof Rule (Screenshots/Logs for visual tasks)
- **Verified Facts**: [List specific confirmed implementation details]
- **Unverified Risks**: [List any remaining ambiguities or risks]
- **Next Bounded Move**: [The single most effective next action]
```

## 2. VISUAL PROOF PACKAGES (Rule 6)
For any visual/polish task, the agent must produce proof in:
`_visual_proofs/[task_name]/`
  - `screenshots/`: After the change (and before/after if replacing).
  - `logs/`: Validation logs or runtime console output.
  - `notes/`: Visual-readability observations.
  - `recordings/`: (Optional) short gameplay capture.

Do not claim visual success without these artifacts unless capture is technically impossible.

## 3. VALIDATION DISCIPLINE
- **Tier 1 (Inspected)**: Files read.
- **Tier 2 (Static)**: `validate_project.bat` or `tsc` or `ruff` passed.
- **Tier 3 (Runtime)**: Project ran, behavior exercised.
- **Tier 4 (Playtest)**: Manual verification of "feel."

## 4. REPORT SCORING
Automated scoring is available to catch mechanical gaps in reporting.
`python tools/ai/score_agent_report.py path/to/report.md`

- **Scoring Guide**: `docs/ai/REPORT_CONTRACT.md`
- **Template**: `agent_reports/REPORT_TEMPLATE.md`

## 5. SELF-UPGRADE CHECK (Required in Every Substantial Report)

After completing an implementation or multi-step task, agents must include this
section in the Auditor's Report. Most answers will be "no" — that is correct.
Only act when a genuine change is detected. See `docs/ai/LIVING_COMMAND_LOOP.md`
for the full Evolution Gate definition.

```md
## Self-Upgrade Check
- **Repo Truth Changed**: yes / no — [brief reason if yes]
- **Player Understanding Changed**: yes / no — [what changed for the player if yes]
- **Current Pulse Update Needed**: yes / no — [what changed if yes]
- **Agent Rule Update Needed**: yes / no — [which rule and why if yes]
- **New Eval Case Needed**: yes / no — [drift type or lesson if yes]
- **Soul / Taste Lesson Learned**: yes / no — [what Cody clarified if yes]
- **Recommended Doctrine Patch**: none / pulse / rule / hook / eval / proposal
- **One-Sentence Learning**: [what this task confirmed, corrected, or revealed]
```

Allowed direct updates (no approval):
- `docs/ai/CURRENT_PULSE.md` — when confirmed repo truth changed.
- `tools/ai/evals/wwf_agent_soul_cases.yml` — when a new drift case is confirmed.

Approval required (propose, do not implement):
- Any change to SOVEREIGN_CORE.md, AI_ARCHITECTURE_LEDGER.md, GAME_SPINE.md,
  AGENTS.md, CLAUDE.md, GEMINI.md, lockbox docs, or protected system rules.

## 6. HANDOFF FORMAT
When passing work to another agent:
- **Target File(s)**: [PATHS]
- **Working Truth**: [CONTEXT_LIMIT]
- **Bounded Goal**: [TASK_DESCRIPTION]
- **Validation Requirement**: [SPECIFIC_CHECK]
