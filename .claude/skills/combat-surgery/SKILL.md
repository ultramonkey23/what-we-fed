---
name: combat-surgery
description: Perform bounded WHAT WE FED combat code changes while preserving timing truth, input response, lane readability, support readability, and combat honesty.
allowed-tools: Read, Grep, Glob, Edit, MultiEdit, Bash
---

# Combat Surgery

Use for combat fixes or focused combat improvements.

## Procedure
1. State the exact combat contract being protected.
2. Inspect live owners first: `scenes/combat/CombatScene.gd`, then the smallest relevant set of `PlayerCombat.gd`, `LaneManager.gd`, `systems/CombatMeter.gd`, `systems/SongConductor.gd`, `systems/SupportEffectResolver.gd`, and data owners.
3. Trace signal and data ownership before moving logic.
4. Patch the smallest behavior-preserving surface.
5. Avoid active-combat pauses, hidden hit/miss outcomes, unreadable VFX, or generic reward/stat soup.
6. Validate with `smoke_project.bat`; use `debug_harness.bat` or `run_project.bat` when timing, readability, or feel is part of the claim.

## Output
- Contract protected.
- Files changed.
- Blast radius.
- Validation run.
- What remains unverified.
