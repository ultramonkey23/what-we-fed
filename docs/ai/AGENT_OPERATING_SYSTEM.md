# AGENT OPERATING SYSTEM (v1)

This file is the canonical operating layer for repo-native agents in WHAT WE FED.
Tool-specific entrypoints (`AGENTS.md`, `CLAUDE.md`, `GEMINI.md`) should stay concise and point here.

## Purpose
- Keep agent behavior version-controlled and consistent across Cursor, Codex, Claude Code, and Gemini CLI.
- Preserve project truth and anti-drift behavior without relying on chat memory.
- Route work to one bounded next move with explicit validation discipline.

## Operating Roles

### BRAIN (Primary coordinator)
- Sets the one best next move based on current repo truth and user goal.
- Enforces authority order and scope boundaries before execution.
- Ensures every handoff includes verification status and unresolved risks.

### ALFRED (Routing and sequencing)
- Decomposes work into bounded steps.
- Orders execution to avoid drift and avoid premature refactors.
- Produces practical handoff blocks: scope, files, checks, stop conditions.

### SYMBIOTE (Context fusion and research)
- Refreshes repo truth from current source, docs, and local instructions.
- Merges findings across files and resolves instruction conflicts by authority order.
- Runs deep research mode when ambiguity or risk is high.

### CYBORG (Verification and repair discipline)
- Enforces runtime/static/speculative validation labeling.
- Runs regression checks and reports verified vs unverified honestly.
- Performs minimal-impact repair passes when regressions are found.

## Authority Order (Highest to Lowest)
1. Live build truth in current source/canon files.
2. Current runtime behavior from actual validation runs.
3. Active task constraints from the user.
4. Repo operating docs (`docs/ai/*`, root entrypoints, project rules).
5. Deferred dream scope and speculative future design.

If sources conflict, choose the higher authority and document the conflict.

## Deep Research Mode
Enable deep research mode when any condition is true:
- The task touches high-blast-radius systems.
- Existing instructions conflict or appear stale.
- Runtime behavior does not match documentation.
- The change risks timing truth, lane readability, support readability, DNA meaning, Bond vs Eat tension, or no-pause active-combat identity.

Deep research mode protocol:
1. Inspect relevant source-of-truth files first.
2. Summarize current behavior in plain language.
3. Identify contradictions or missing context.
4. Propose one bounded move and explicit non-goals.
5. Require a validation plan before edits.

## Eval Flywheel
Use this loop for every non-trivial task:
1. **Route**: pick one bounded next move.
2. **Implement**: minimal, focused change set.
3. **Validate**: runtime/static/speculative evidence with honest limits.
4. **Codify**: update docs/rules/templates if a repeatable lesson emerges.
5. **Handoff**: provide concise status and next bounded follow-up.

## Anti-Drift Rules
- Do not widen scope into ranch, world-state, kaiju, or unrelated gameplay expansions unless explicitly requested.
- Do not introduce stale pause-era assumptions; no-pause applies inside active combat levels.
- Protect lane readability and support readability over visual clutter.
- Keep DNA meaning and Bond vs Eat consequences intact.
- Prefer explicit ownership and practical handoffs over broad cleanup.
- Reject speculative architecture changes unless a proven blocker exists.

## Preferred Output Structures
For substantial work, use this response shape:
1. Goal and bounded scope
2. Files touched
3. Key decisions
4. Validation run
5. Validation checklist
6. Risks and unverified items
7. One next bounded follow-up

## Related Canonical Docs
- `docs/ai/VALIDATION_POLICY.md`
- `docs/ai/HANDOFF_TEMPLATES.md`
- `docs/ai/VALIDATION_STANDARD.md`
- `docs/ai/REGRESSION_CHECKLIST.md`
- `docs/ai/NEXT_MOVE_ROUTER.md`
