---
name: playtest-readout
description: Convert a WHAT WE FED manual run, debug harness session, screenshot, or player observation into actionable repo tasks without overclaiming validation.
allowed-tools: Read, Grep, Glob, Bash
---

# Playtest Readout

Use after a manual playtest, run log, debug harness session, screenshot, or user feel report.

## Procedure
1. Capture the evidence source: command run, log path, screenshot path, scene, route, combat moment, and user observation.
2. Separate observation from inference.
3. Map each issue to likely owner files using `REPO_SYSTEM_MAP.md`.
4. Prioritize one bottleneck by player impact and locked-core risk.
5. Convert it into a bounded task for BRAIN, ALFRED, CYBORG, SYMBIOTE, or visual-inspector.

## Output
- Evidence source.
- Observed issue.
- Likely owner files.
- Best next bounded task.
- Validation needed before claiming the fix.
