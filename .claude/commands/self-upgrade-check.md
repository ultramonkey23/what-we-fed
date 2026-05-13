# /self-upgrade-check

Run the WHAT WE FED Evolution Gate after completing a task.
Most answers will be "no" — that is correct. Only act on a genuine "yes."

## The 5 Checks

1. **Repo Truth Delta** — did confirmed repo truth change?
   Yes → update `docs/ai/CURRENT_PULSE.md` (compact entry only).

2. **Player Understanding Delta** — did anything player-facing change?
   Yes → note in Verified Facts; if visual, produce visual proof first.

3. **Soul Delta** — did Cody's design intent or taste become clearer?
   Yes → pulse entry / agent rule / or evolution proposal (depending on scope).

4. **Agent Drift Check** — was a repeatable mistake made or avoided?
   Yes → add/update eval case in `tools/ai/evals/wwf_agent_soul_cases.yml`.

5. **Eval Case Rule** — should an existing eval case be updated or retired?

## Append this block to the Auditor's Report

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

## What can be updated directly (no approval)
- `docs/ai/CURRENT_PULSE.md` — when confirmed repo truth changed.
- `tools/ai/evals/wwf_agent_soul_cases.yml` — when a drift case is confirmed.

## What requires approval (write a proposal instead)
Everything else — SOVEREIGN_CORE, GAME_SPINE, AGENTS.md, CLAUDE.md, GEMINI.md,
lockbox docs, agent roles, art-style doctrine, combat/economy spine.

See `docs/ai/LIVING_COMMAND_LOOP.md` for the full Evolution Gate definition.
