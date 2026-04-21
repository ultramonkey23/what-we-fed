# VALIDATION POLICY (v1)

This file defines the validation contract for repo-native agent work.
Use with `docs/ai/VALIDATION_STANDARD.md` and `docs/ai/REGRESSION_CHECKLIST.md`.

## Validation Evidence Types

### Runtime-Verified
Use when behavior was exercised by running project validation scripts and/or a manual game run.

Required reporting:
- Exact commands run.
- Pass/fail outcomes.
- What behavior was observed.
- What still remains unverified.

### Static-Only
Use when verification is based on code inspection, static analysis, linting, structure, or syntax checks only.

Required reporting:
- Which static checks were performed.
- Why runtime validation was not run.
- Risk statement for runtime unknowns.

### Speculative
Use when a claim is inferred but not validated by runtime or sufficient static evidence.

Required reporting:
- Mark clearly as speculative.
- State what evidence is missing.
- Provide the minimal next check needed to confirm or reject.

## Validation Run Template
Copy and fill this block in final reports:

```md
## Validation run
- Scope type: <runtime-verified | static-only | speculative>
- Commands:
  - `<command 1>`
  - `<command 2>`
- Result:
  - `<pass/fail and key observations>`
- Unverified:
  - `<explicit gaps>`
```

## Validation Checklist Template
Copy and fill this block in final reports:

```md
## Validation checklist
- [ ] Paths/references updated and valid
- [ ] Syntax/config validation passed (JSON/frontmatter/rules)
- [ ] Gameplay flow not unintentionally changed
- [ ] UI/readability regressions reviewed or explicitly unverified
- [ ] Timing/lane/support readability constraints preserved
- [ ] Bond vs Eat and DNA meaning constraints preserved
- [ ] No stale pause-era assumptions introduced
```

## Regression Rules

### Gameplay Regression Rules
- No unintended gameplay system change in a workflow-only task.
- No scene flow changes unless explicitly scoped.
- No balance changes unless explicitly scoped.

### UI and Readability Regression Rules
- Maintain lane readability and support readability.
- Do not claim visual clarity validation without runtime evidence.
- Treat clutter, telegraph masking, and readability confusion as regressions.

### Flow Regression Rules
- No-pause active-combat identity remains locked.
- Between-level reward/inventory pacing remains allowed and distinct from in-combat flow.
- Title -> Lair -> Route -> Combat expectations must not be silently altered.

## Reporting Honesty Rule
- Always separate verified facts from assumptions.
- Always list what was not tested.
- If runtime was not executed, state that clearly and avoid runtime certainty claims.
