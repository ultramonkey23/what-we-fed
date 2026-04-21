# HANDOFF TEMPLATES (v1)

Use these templates to keep cross-tool handoffs consistent and bounded.
Each template must preserve repo truth and explicitly separate verified vs unverified claims.

## Claude Handoff Template

```md
# Claude Handoff

## Goal
<one bounded objective>

## Scope
- In scope: <files/systems>
- Out of scope: <explicit non-goals>

## Repo Truth Anchors
- `AGENTS.md`
- `docs/ai/AGENT_OPERATING_SYSTEM.md`
- `docs/ai/VALIDATION_POLICY.md`

## Plan
1. <step>
2. <step>

## Validation
- Required checks: <runtime/static checks>
- Verified: <facts>
- Unverified: <gaps>

## Risks
- <risk and containment>

## One next bounded follow-up
- <single next move>
```

## Codex Handoff Template

```md
# Codex Handoff

## Mission
<one bounded move aligned to current repo truth>

## Constraints
- Preserve timing truth, lane readability, support readability.
- Preserve DNA meaning and Bond vs Eat tension.
- Preserve no-pause active-combat identity.

## File Targets
- <path 1>
- <path 2>

## Deliverable Format
- Files changed
- Key decision points
- Validation run
- Validation checklist
- Risks
- One next bounded follow-up

## Validation status
- Runtime-verified: <yes/no + evidence>
- Static-only: <yes/no + evidence>
- Speculative: <yes/no + reason>
```

## Cursor Handoff Template

```md
# Cursor Handoff

## Task
<bounded objective>

## Read first
- `AGENTS.md`
- `docs/ai/AGENT_OPERATING_SYSTEM.md`
- `docs/ai/VALIDATION_POLICY.md`

## Execution boundaries
- Do not widen into unrelated gameplay scope.
- Do not refactor broadly unless required by a proven blocker.

## Validation requirements
- Run or clearly defer required checks.
- Report verified vs unverified explicitly.

## Output contract
- What changed
- Why it changed
- What was validated
- What remains unverified
- One next bounded follow-up
```

## Gemini Research / Rescan Template

```md
# Gemini Research Rescan

## Research target
<question/problem to resolve>

## Authority order
1. Live build source truth
2. Runtime evidence
3. Task constraints
4. Operating docs

## Scan scope
- Paths: <target paths>
- Exclusions: <out-of-scope areas>

## Findings
- Confirmed facts:
  - <fact>
- Conflicts or stale guidance:
  - <conflict>

## Recommendation
- One best next move: <bounded move>
- Why now: <reason>
- What waits: <deferred items>

## Validation status
- Runtime-verified:
- Static-only:
- Speculative:
```

## Shared Handoff Rule
- Keep handoffs short, executable, and evidence-based.
- Prefer one bounded next move over broad multi-track plans.
