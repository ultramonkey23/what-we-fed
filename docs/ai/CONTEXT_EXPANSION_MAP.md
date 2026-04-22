# WHAT WE FED — CONTEXT EXPANSION MAP

Default-load only:
- `docs/ai/PROJECT_KERNEL.md`
- one tool entrypoint (`AGENTS.md` / `CLAUDE.md` / `GEMINI.md` / `.github/copilot-instructions.md`)

Open deeper files only when task needs them.

## Routing by Task Type

### Combat timing / lane behavior / support readability
- Open:
  - `scenes/combat/CombatScene.gd`
  - `systems/SongConductor.gd`
  - `systems/CombatMeter.gd`
  - `autoloads/EventBus.gd`
  - `.cursor/rules/combat-timing-hotpath.mdc`
  - `docs/ai/VALIDATION_STANDARD.md`
- Use when: timing honesty, lane clarity, combat flow, support telegraphs are touched.

### Runtime safety / validation evidence
- Open:
  - `PROJECT_SETUP_AND_VALIDATION.md`
  - `docs/ai/VALIDATION_POLICY.md`
  - `docs/ai/REGRESSION_CHECKLIST.md`
  - `.cursor/rules/gdscript-validation.mdc`
- Use when: making runtime-impacting edits or claiming behavior changes.

### Agent workflow / mutation discipline
- Open:
  - `docs/ai/AGENT_OPERATING_SYSTEM.md`
  - `docs/ai/NEXT_MOVE_ROUTER.md`
  - `docs/ai/HANDOFF_TEMPLATES.md`
  - `.cursor/rules/20-routing-and-handoffs.mdc`
- Use when: planning medium/high mutation or drafting structured handoffs.

### Canon identity / anti-drift decisions
- Open:
  - `docs/WHAT_WE_FED__LOCKED_CORE_EVOLVING_SPINE_DOCTRINE.md`
  - `docs/GAME_SPINE.md`
  - `docs/GAME_SOUL_AND_CORE_FANTASY.md`
  - `.cursor/rules/30-what-we-fed-guardrails.mdc`
- Use when: proposed change may alter identity, loop framing, or tone.

### Scope arbitration (live build vs later/deferred)
- Open:
  - `docs/NEXT_PHASE_PLAN.md`
  - `docs/DEMO_MILESTONE_LADDER.md`
  - `docs/WHAT_WE_FED_FINAL_GAME_SCOPE_CANON_FLAGSHIP.md`
  - `docs/FUTURE_RANCH_PLAN.md`
- Use when: deciding if a request is near-term, later-scope, or deferred.

### Data/content ownership and extraction
- Open:
  - `REPO_SYSTEM_MAP.md`
  - `data/` owners relevant to task
  - `docs/SONG_LEVEL_STRUCTURE.md`
- Use when: moving hardcoded content, tuning combat content, or schema ownership questions.

## Deep Reference Only (Do Not Default-Load)
- `docs/WHAT_WE_FED_FINAL_GAME_SCOPE_CANON_FLAGSHIP.md`
- `docs/THE_HOLLOW_EGG_KAIJU_ASCENSION_CANON.md`
- `docs/FUTURE_RANCH_PLAN.md`
- role packs / agent profiles in `docs/ai/ROLE_PACKS/` and `docs/ai/agents/`
- implementation summaries/plans in `docs/*IMPLEMENTATION*.md`

## Escalation Rule
- If kernel + one route file do not resolve conflict, open the minimum additional file from this map.
- Record when lower-authority wording is retired by higher-authority live truth.
