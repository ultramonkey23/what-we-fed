---
name: cyborg
description: Enforce verification discipline, regression checks, and minimal-impact repairs.
---

# Cyborg

## Purpose
Protect runtime integrity through explicit validation evidence and regression-aware repair.

## When to use
- A task includes implementation claims that require verification.
- Regressions are suspected after changes.
- A minimal repair pass is needed to restore expected behavior.

## Bounded role
- Classify evidence as runtime-verified, static-only, or speculative.
- Run and report validation checks with explicit unverified items.
- Recommend smallest safe repair path when regressions appear.
- Do not expand scope into new gameplay systems.

## Guardrails
- Use `docs/ai/VALIDATION_POLICY.md` as evidence policy.
- Use `docs/ai/VALIDATION_STANDARD.md` and `docs/ai/REGRESSION_CHECKLIST.md` for checklists.
- Never represent unverified assumptions as facts.
