# CURRENT_REPO_TRUTH_LEDGER

## Evidence Source
- Source: GODLY v2.3 medium-evolution validation pass.
- Last verified by: Codex.
- Verified date: 2026-04-25.
- Verified commit: `304330050ca47612671c44ba0c4e7127c4a7feef`.
- Audit context commit: `304330050ca47612671c44ba0c4e7127c4a7feef`.
- Validation level: 3 — Automated headless validation.
- Validation method: static file/code inspection plus `validate_data.bat`, `validate_project.bat`, and `smoke_project.bat`.
- Runtime validation: Headless one-frame project boot passed via smoke/validate wrappers; live gameplay feel was not manually validated.
- Manual playtest validation: Not performed.

## 2026-04-25 GODLY v2.3 Automated Validation Evidence
- `validate_data.bat`: PASS. Data validator now includes `PerformanceRewardContent.gd` reward-order, mix-reference, required-display-field, `effect.type`, and `flayed_vessel` Vessel payoff schema checks.
- `validate_project.bat`: PASS. The wrapper retried import in headless mode after a Windows renderer/import issue, then completed with `VALIDATE OK` and chained passing data validation.
- `smoke_project.bat`: PASS. Headless one-frame boot completed with `SMOKE OK`.
- Targeted diff review: PASS for scoped changed files. `git diff --check` reported only a line-ending normalization warning for `tools/validate_data_content.gd`.
- Manual playtest: Not performed; HUD readability and live predation-offer presentation remain manual-validation items.

## Verified Current Systems (Static / Code-Confirmed)
- Combat lane model: implemented in code as a 4-cardinal-lane model in `LaneManager.gd` (runtime behavior unverified).
- Input core: `PlayerCombat.gd` contains buffering/recovery/i-frame mechanisms. Input buffer set to 0.14s.
- DNA Economy Fix (v2.3.1): `VictoryRewardDirector.gd` resolved a confirmed bug where choosing to 'Eat' incorrectly consumed DNA. 'Eat' is now correctly verified as a predation/gain path, not a consumer path.
- Reward Flow Integrity: `VictoryRewardDirector.gd` now includes a `reset()` method called during `CombatScene` destruction to prevent stale reward leakage between runs.
- Core state/autoload presence: `EventBus.gd` and `GameState.gd` exist as core systems and are autoloaded in `project.godot`.
- Performance reward data validation: implemented in `tools/validate_data_content.gd`.

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
- `tools/validate_data_content.gd` (performance reward validation coverage)
- `systems/PerformanceRewardDirector.gd` (predation-pool pending trigger)
- `systems/VesselModifierDirector.gd` (Vessel modifier display readout)
- `systems/CombatHUDPresenter.gd` (support HUD Vessel cue)

## Validated Behavior
- Validation scope for this ledger entry is static/file/code inspection plus automated headless Godot validation.
- Headless project boot and automated data/project validation passed for the current commit.
- No manual gameplay feel/readability behavior is validated by this ledger entry.
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
