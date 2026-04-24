# CURRENT_REPO_TRUTH_LEDGER

## Evidence Source
- Source: Gemini audit summary provided in current task context.
- Validation method: static/file/code review summary only.
- Explicit non-evidence: no Godot launch and no manual playtest confirmed by this seed.

## Verified Current Systems
- Combat: functional 4-cardinal-lane rhythm combat system.
- Input: `PlayerCombat.gd` has robust input buffering, recovery, and i-frame logic.
- Rhythm: `SongConductor.gd` exists and drives beat timing.
- State: `EventBus.gd` and `GameState.gd` exist as core systems.

## Files Confirmed Touched / Inspected
- `scenes/combat/CombatScene.gd` (architecture risk focus)
- `scenes/combat/PlayerCombat.gd` (input robustness focus)
- `systems/SongConductor.gd` (rhythm timing system exists)
- `autoloads/EventBus.gd` (core system exists)
- `autoloads/GameState.gd` (core system exists)

## Validated Behavior
- Validation scope for this seeded ledger is static/file/code review only.
- No runtime or manual gameplay behavior is validated in this seed.

## Unverified Claims
- Any claim requiring Godot runtime execution.
- Any claim requiring manual lane readability/playability confirmation.
- Any claim requiring end-to-end song/run/lair flow playthrough confirmation.

## Known Failures / Risks
- Repo is functional but fragile (from audit summary).
- Architecture risk: `CombatScene.gd` monolith around 6,728 lines.

## Design vs Repo Mismatches
- No mismatch asserted in this seed beyond documented architecture fragility risk.

## Current Implementation Status
| Area | Status | Evidence |
|---|---|---|
| Combat lane model | Present | Audit: 4-cardinal-lane rhythm combat |
| Player combat input core | Present | Audit: robust buffering/recovery/i-frame logic |
| Combat scene architecture | Risk | Audit: monolith around 6,728 lines |
| Rhythm conductor | Present | Audit: `SongConductor.gd` exists and drives beat timing |
| Core state bus | Present | Audit: `EventBus.gd` exists |
| Core game state | Present | Audit: `GameState.gd` exists |
| Runtime validation | Unverified | No launch/manual playtest confirmed in seed |

## Next Safest Repo Action
- Run a bounded runtime verification pass (launch + smoke + manual lane/readability checks) before any combat refactor claims.

## Ledger Update Rule
- Add or update entries only with directly inspected evidence.
- Label runtime claims as validated only when backed by executed checks/playtests.
- Keep unverified claims explicitly separated until evidence is collected.
