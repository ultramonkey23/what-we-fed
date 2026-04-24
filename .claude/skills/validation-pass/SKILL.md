---
name: validation-pass
description: Run and report WHAT WE FED validation honestly. Use after code, data, asset, scene, hook, or workflow changes.
allowed-tools: Read, Grep, Glob, Bash
---

# Validation Pass

Use this whenever the repo needs proof rather than confidence.

## Command Ladder
1. For script-only or workflow changes: `smoke_project.bat`.
2. For data/content changes: `validate_data.bat`, then `smoke_project.bat`.
3. For imports, assets, scenes, or handoff-ready changes: `validate_project.bat`.
4. For combat-state checks: `debug_harness.bat`.
5. For gameplay feel, input response, or readability claims: `run_project.bat` plus explicit manual observations.

## Reporting Rules
- Do not call smoke/validate a gameplay feel test.
- Report exact command names and whether they passed, failed, or were skipped.
- If skipped, state why.
- Treat parse errors, script errors, user errors, and unexpected runtime errors as real failures.
- Known safe Windows warnings may be noted, but do not hide other errors behind them.

## Output
Return validation evidence type: runtime-verified, data-validated, static-only, visual-evidence, or speculative.
