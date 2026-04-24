# CURRENT_REPO_TRUTH_LEDGER

## Evidence Source
- Source: Current Repo Truth Ledger Audit.
- Last verified by: Codex (static audit pass).
- Verified date: 2026-04-24.
- Verified commit: `113c23a1ced258ab9f44e2db6550e433c1b824c7`.
- Audit context commit: `e8b4e7219657ad402f8aecc66f15bb400596c42f`.
- Validation level: 2 — Static validated.
- Validation method: static file/code inspection only.
- Runtime validation: Not performed.
- Manual playtest validation: Not performed.

## Verified Current Systems (Static / Code-Confirmed)
- Combat lane model: implemented in code as a 4-cardinal-lane model in `LaneManager.gd` (runtime behavior unverified).
- Input core: `PlayerCombat.gd` contains buffering/recovery/i-frame mechanisms (runtime reliability and feel unverified).
- Rhythm core: `SongConductor.gd` implements beat logic and beat-related signals (runtime sync/readability unverified).
- Projectile timing: `Projectile.gd` contains progress/timing evaluation logic (runtime timing feel unverified).
- Core state/autoload presence: `EventBus.gd` and `GameState.gd` exist as core systems and are autoloaded in `project.godot`.

## Files Confirmed Touched / Inspected
- `scenes/combat/CombatScene.gd` (architecture-risk check)
- `scenes/combat/PlayerCombat.gd` (input mechanism check)
- `scenes/combat/LaneManager.gd` (lane topology check)
- `scenes/combat/Projectile.gd` (timing/progress mechanism check)
- `systems/SongConductor.gd` (beat system check)
- `systems/CombatMeter.gd` (combat meter signal/tier context check)
- `autoloads/EventBus.gd` (core system existence)
- `autoloads/GameState.gd` (core system existence)
- `data/CombatContent.gd` (content-level combat wiring context)
- `project.godot` (autoload/main-scene context)

## Validated Behavior
- Validation scope for this ledger entry is static/file/code inspection only.
- No runtime gameplay behavior is validated by this ledger entry.
- No manual feel/readability/combat-honesty behavior is validated by this ledger entry.

## Unverified / Needs Validation
- Runtime functionality in live Godot execution.
- Full mini-run completion flow (`TitleScreen -> LairScene -> RouteScene -> CombatScene`) under current build.
- Actual combat feel (timing truth perception, pressure readability, attack authority clarity).
- Input reliability in play (including edge cases under live frame pacing).
- Rhythm feel/sync perception during real encounters.
- Lane/readability/combat honesty under real combat pressure.
- Keyboard vs controller feel parity and stability.
- Balance outcomes (damage, stamina, support gain, reward pacing).
- Stability of these systems after future edits.

## Known Failures / Risks
- Architecture risk: `CombatScene.gd` remains a large monolith and extends to about line 6899 in the latest static inspection.
- Stale-truth risk: static code presence can be misread as runtime-confirmed behavior if validation caveats are omitted.

## Design vs Repo Mismatches
- No major design-intent-as-implementation mismatch was asserted in this static pass.

## Current Implementation Status (Code Presence vs Behavioral Validation)
| Area | Code Presence | Behavioral Validation |
|---|---|---|
| Combat lane model | Present in `LaneManager.gd` (4-cardinal lanes) | Runtime unverified |
| Player combat input core | Present in `PlayerCombat.gd` (buffer/recovery/i-frame mechanisms) | Runtime reliability/feel unverified |
| Combat scene architecture | `CombatScene.gd` present and large (about 6899 lines) | Maintainability risk inferred; runtime impact unverified |
| Rhythm conductor | Present in `SongConductor.gd` (beat logic/signals) | Runtime timing feel/sync unverified |
| Projectile timing logic | Present in `Projectile.gd` (progress/timing evaluations) | Runtime timing honesty/readability unverified |
| Core state bus | `EventBus.gd` present/autoloaded | Runtime interaction outcomes unverified |
| Core game state | `GameState.gd` present/autoloaded | Runtime progression behavior unverified |
| Runtime validation | Not evidenced in this ledger entry | Unverified |
| Manual playtest validation | Not evidenced in this ledger entry | Unverified |

## Next Safest Repo Action
- Run a bounded runtime verification + manual playtest pass, then update this ledger with explicit validation evidence and level.

## Ledger Update Rule
- Add/update entries only with directly inspected evidence.
- Use "implemented in code" / "static inspection found" for static-only truth.
- Mark runtime claims as validated only when backed by executed runtime checks/playtests.
- Keep unverified claims explicitly separated until evidence is collected.
