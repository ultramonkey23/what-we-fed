# CURRENT REPO TRUTH LEDGER

## Evidence Source
- Source: Fresh Gemini audit summary provided in task context.
- Validation type: static/file/code review only.
- Not confirmed in this ledger: Godot launch, runtime execution, manual playtest.

## Verified Current Systems
- Combat: functional 4-cardinal-lane rhythm combat.
- Input: `PlayerCombat.gd` has robust input buffering/recovery/i-frame logic.
- Rhythm: `SongConductor.gd` exists and drives beat timing.
- State: `EventBus.gd` and `GameState.gd` exist as core systems.

## Files Confirmed Touched / Inspected
- By audit claim: `scenes/combat/CombatScene.gd`
- By audit claim: `scenes/combat/PlayerCombat.gd`
- By audit claim: `systems/SongConductor.gd`
- By audit claim: `autoloads/EventBus.gd`
- By audit claim: `autoloads/GameState.gd`

## Validated Behavior
- Static repo review indicates combat is currently functional in a 4-cardinal-lane rhythm model.
- Static repo review indicates player input handling logic in `PlayerCombat.gd` is robust (buffering/recovery/i-frames).

## Unverified Claims
- Any runtime gameplay quality claim not backed by a fresh local run in this task.
- Any manual playtest outcome not recorded with steps and expected/actual behavior.
- Any balance/performance claim beyond static inspection.

## Known Failures / Risks
- Architecture risk: `CombatScene.gd` is a large monolith (around 6,728 lines), increasing fragility and regression risk.

## Design vs Repo Mismatches
- None added in this seed ledger beyond the documented architecture fragility risk.

## Current Implementation Status
| System | Status | Evidence | Confidence |
|---|---|---|---|
| 4-cardinal-lane combat | Present | Gemini audit summary | Medium (static only) |
| Player input buffering/recovery/i-frames | Present | Gemini audit summary | Medium (static only) |
| Song beat timing conductor | Present | Gemini audit summary (`SongConductor.gd`) | Medium (static only) |
| Core state/event systems | Present | Gemini audit summary (`EventBus.gd`, `GameState.gd`) | Medium (static only) |
| Runtime/manual validation for above | Not validated in this ledger | No Godot launch/playtest confirmed | High |

## Next Safest Repo Action
- Run a bounded runtime validation pass (Godot launch + short manual combat check) and append only observed results.

## Ledger Update Rule
- Add or change entries only when backed by direct evidence from:
  - local file inspection with exact file paths, and/or
  - reproducible runtime validation steps with observed outcomes.
- Mark uncertainty explicitly as unverified.
- Do not promote design intent or assumptions to repo truth.
