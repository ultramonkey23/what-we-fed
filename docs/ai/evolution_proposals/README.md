# AI EVOLUTION PROPOSALS

This folder is the controlled intake for proposed changes to WHAT WE FED AI architecture, canon routing, doctrine, documentation structure, or protected workflows.

Agents may create proposals here, but may not implement them without explicit human or Command Center approval.

## When To Use
- A doctrine source conflicts with repo truth.
- An entrypoint repeats or contradicts another entrypoint.
- A large historical ledger should be migrated or compacted.
- A protected-system rule needs revision.
- A role, routing rule, validation rule, or canon boundary should change.
- A stale doc should be pruned, archived, renamed, or replaced.

## Required Proposal Format

```md
# Proposal: [short title]

## Problem Observed
[What is wrong, confusing, stale, duplicated, or risky?]

## Evidence
- [file/path.md:line or inspected repo fact]
- [runtime/report evidence if available]

## Affected Files/Systems
- [docs or systems affected]

## Proposed Change
[Smallest controlled change.]

## Risk
[What could drift, break, or confuse future agents?]

## Validation Plan
[Searches, doc checks, runtime checks, visual proof, or review needed.]

## Rollback Plan
[How to revert if the change is rejected or causes confusion.]

## Approval Required
[Human / Command Center / specific owner.]
```

## Rules
- Separate confirmed repo truth, user-reported truth, design direction, and future ideas.
- Do not rewrite canon, architecture, GAME_SPINE, or lockbox doctrine inside a proposal.
- Do not implement proposal content until approval is explicit.
- Do not move or archive large doc groups through an unapproved proposal.
- Do not use proposals to bypass protected-system validation.
- Visual/demo polish proposals must include a visual proof plan when technically possible.

## Naming
Use a date and short slug:

`YYYY-MM-DD_short_slug.md`

Example:

`2026-05-04_current_pulse_migration.md`
