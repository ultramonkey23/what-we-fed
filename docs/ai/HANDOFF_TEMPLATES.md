# HANDOFF TEMPLATES (v1.2 Universal Workflow)

Use these templates to keep cross-tool handoffs consistent and bounded.
Every agent (Claude, Gemini, Cursor, Copilot, Codex) MUST use the same Universal Reporting Block at the end of their task.

## 1. Task Initialization & Mutation Budget

When starting a task, state your budget and guardrails:

```md
## Mutation budget
- Level: <low|medium|high>
- Why this level: <brief rationale>

## Controlled mutation guardrails
- Timing truth test: <pass/fail/pending>
- Lane readability test: <pass/fail/pending>
- Support readability test: <pass/fail/pending>
- DNA / Bond-Eat meaning test: <pass/fail/pending>
- Combat-clean, management-rich test: <pass/fail/pending>
```

*Rule: Low mutation tasks stay single-path. Medium/high mutation tasks must include dual-track output (Safe path vs Mutation path) before proceeding.*

## 2. The Universal Reporting Block (The Reporting Law)

At the completion of any task (Inspect, Spec, Patch, Validate, or Evolve), you MUST provide this exact block. This unifies reporting across all AI tools in the repo.

```md
## Read
- <files or systems investigated>

## Confirmed
- <verified facts from current live build or code>

## Strong inference
- <educated assumptions, explicitly marked as unverified>

## Unknown
- <blind spots or risks not investigated>

## Task type
- <Inspect | Spec | Patch | Validate | Evolve>

## Authority layer(s)
- <creator intent | repo truth | live-build truth | evolving spine | older canon/source docs>

## Changes made
- <Brief list of targeted modifications>

## What was not changed
- <Explicitly state what was intentionally left alone to prevent drift>

## Risks
- <Potential breakage or side effects>

## Validation run
- Scope type: <runtime-verified | static-only | speculative>
- Commands: <commands run, if any>
- Result: <pass/fail and key observations>
- What was actually verified: <proven facts>
- What remains unverified: <explicit gaps>

## Validation checklist
- [ ] Creator Intent alignment / Technical Risk analysis
- [ ] Repo Truth (Layer 2) verified and implementation reality respected
- [ ] Timing truth / combat honesty guidance followed
- [ ] Lane readability / support readability protected
- [ ] Anti-sludge (no active-combat menu interruption)
- [ ] Anti-drift (no generic roguelite/survivor flattening)
- [ ] Older canon not allowed to block creator direction

## Next best move
- <One bounded action or recommendation>
```

## Shared Handoff Rule
- Keep handoffs short, executable, and evidence-based.
- Do not fragment reporting formats based on the AI tool used. The Universal Reporting Block is the single standard.
- Always end with one recommended bounded next move.
