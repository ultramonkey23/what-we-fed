---
name: repo-truth-update
description: Update WHAT WE FED repo truth after implementation changes or when docs conflict with live source. Use when preserving current implementation reality matters more than old canon.
allowed-tools: Read, Grep, Glob, Edit, MultiEdit, Bash
---

# Repo Truth Update

Use this when a task asks to refresh project truth, reconcile stale docs, or record a verified implementation state.

## Procedure
1. Read `CLAUDE.md`, `AGENTS.md`, `REPO_SYSTEM_MAP.md`, and the specific runtime files involved.
2. Separate facts into: creator instruction, repo truth, live-build evidence, evolving spine, old canon, deferred dream scope.
3. Search for conflicting wording before editing docs.
4. Update the smallest durable document that future agents actually load.
5. Keep always-loaded context concise. Move procedures into skills and deep reference into docs.
6. If implementation was not runtime-verified, label the update as static-only.

## Output
- Files updated.
- Repo truth promoted.
- Stale truth softened or retired.
- Validation or evidence used.
- Remaining uncertainty.
