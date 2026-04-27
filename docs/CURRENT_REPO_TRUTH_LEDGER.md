# CURRENT_REPO_TRUTH_LEDGER

## 2026-04-27 GODLY v2.3 Nightly Closeout Validation Evidence
- `validate_project.bat`: PASS. Parser error for `_travel_time_to_hit_zone` resolved. ID-keyed authority state confirmed.
- `validate_data.bat`: PASS. All data structures remain consistent.
- Targeted diff review: Confirmed permissive movement, chunky dodge, manual support, and any-angle presentation anchors.

## Verified Current Systems (Static / Code-Confirmed)
- Hunting Field Combat Evolution (v2.3.2):
    - **Permissive Action Recovery**: Implemented in `PlayerCombat.gd`. Players can move during lunge recovery without snap-back to origin.
    - **Chunky Soulslike Dodge**: Implemented in `PlayerCombat.gd`. 70-unit distance, 0.10s lunge, 0.42s recovery, 0.18s i-frames (0.24s on-beat). Precise input-based direction.
    - **Any-Angle Spawning & Pressure Director**: Implemented in `LaneManager.gd`. Threats now spawn from any orbit angle; authority system is ID-keyed and supports up to 16 simultaneous strikers.
    - **Manual Creature Support**: Implemented in `PlayerCombat.gd` and `RunGrowth.gd`. Players manually trigger support with `action_support`. On-beat usage grants extra Tendency rewards.
    - **Dynamic Visual Scaffolding**: Implemented in `CombatPresentationController.gd`. Timing rings, lane strips, and markers now anchor to and follow the player's dynamic position rather than screen center.

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
- DNA Economy Fix (v2.3.1): `VictoryRewardDirector.gd` resolved a confirmed bug where choosing to 'Eat' incorrectly consumed DNA.
- Predatory Gain / Maw Logic (v2.3.1.4): `VictoryRewardDirector.gd` now correctly awards DNA (12.5 per offer) when 'Eat' is chosen, aligning with the project's predatory doctrine.
- Maw Marker (v2.3.1.8): `CombatPresentationController.gd` now builds a pulsating red 'MAW' label above enemies that will yield a Hunt Offer upon death, providing clear pre-kill eligibility feedback.
- Predation Instruction Clarity (v2.3.1.7): `PresentationTextContent.gd` hints updated with 'PRESS E TO EAT (GAIN LINEAGE DNA)' to clarify the reward outcome and required input.
- HUD Synchronization (v2.3.1.2): `CombatHUDPresenter.gd` updated to use `GameState.get_effective_dna_threshold()` for DNA slot status, ensuring predation debt is accurately reflected in the HUD.
- Reward Queue Integrity (v2.3.1.4): `VictoryRewardDirector.gd` now preserves 'is_live' and 'timer' state per-item in the queue, preventing mid-combat rewards from losing their timed behavior.
- Cleanup Safety (v2.3.1.4): `CombatScene.gd` now includes null-guards for `lane_manager` during EventBus disconnection to prevent crashes on specific shutdown sequences.
- Label Accuracy (v2.3.1.1): `PresentationTextContent.gd` updated to clarify that only Bonding is DNA-locked, while Eating remains a gain path. Tone adjusted to reflect predatory gain (Maw/Predation logic).
- Reward Flow Integrity: `VictoryRewardDirector.gd` now includes a `reset()` method called during `CombatScene` destruction to prevent stale reward leakage between runs.
- Cross-System Event Leak Audit (v2.3.1.3): Comprehensive audit of `EventBus` connections. Missing disconnections identified and fixed in `CombatScene.gd`, `PlayerCombat.gd`, `RunGrowth.gd`, `VesselModifierDirector.gd`, `EncounterEscalationDirector.gd`, and `CombatHUDPresenter.gd`.
- Signal Cleanup (v2.3.1.3): Every persistent `EventBus` connection in core combat systems now has a verified matching `disconnect()` call in the corresponding `_exit_tree()` or `cleanup()` method.
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
