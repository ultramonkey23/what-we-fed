# AGENTS — WHAT WE FED REPO ENTRYPOINT

This file is the short, cross-tool entrypoint for agent behavior in this repo.
Canonical operating details live in:
- `docs/ai/AGENT_OPERATING_SYSTEM.md`
- `docs/ai/VALIDATION_POLICY.md`
- `docs/ai/HANDOFF_TEMPLATES.md`

## Locked Project Truth (Preserve)
- Timing truth is non-negotiable; `systems/SongConductor.gd` remains master timing authority.
- Lane readability and support readability are protected constraints.
- DNA meaning and Bond vs Eat tension must remain meaningful.
- No-pause applies inside active combat levels; between-level reward/inventory menus are allowed.
- Live build truth outranks dream scope.

## Authority Order
1. Current source/canon files in this repo.
2. Current runtime behavior from validation runs.
3. Active user task constraints.
4. Repo operating docs and tool entrypoints.
5. Deferred/speculative dream scope.

## Operating Rules
- Choose one bounded next move; avoid scope expansion.
- Prefer surgical edits over broad refactors.
- Keep handoffs practical and evidence-based.
- Report validated vs unverified claims explicitly.

## Validation Routing
- Use `docs/ai/VALIDATION_POLICY.md` for validation evidence tiers and reporting format.
- Use `docs/ai/VALIDATION_STANDARD.md` and `docs/ai/REGRESSION_CHECKLIST.md` for runtime checks.
- Any runtime-impact claim is incomplete without validation status.

## Tool-Specific Notes
- Cursor project rules: `.cursor/rules/*.mdc`
- Claude instructions and subagents: `CLAUDE.md`, `.claude/agents/`
- Gemini instructions and subagents: `GEMINI.md`, `.gemini/agents/`
