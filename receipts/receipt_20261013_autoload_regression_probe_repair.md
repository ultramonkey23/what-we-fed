# Production-autoload regression probes restored

LAB_RECEIPT_CONTRACT_V1:
RESULT: PASS
PROJECT_ID: what-we-fed
MISSION: Restore native regression probes so they execute through the registered project autoload graph and preserve current Bond/Eat, state-persistence, and CombatScene-load contracts.
ROUTING_DECISION: rd_1791874125113_12d1890d
FILES_CHANGED: tools/test_bond_eat_logic.gd; tools/test_state_persistence.gd; tools/test_combat_scene.gd; receipts/receipt_20261013_autoload_regression_probe_repair.md
START_HEAD: aa6391e664
END_HEAD: pending-finish
COMMIT: pending-finish
VALIDATION_RESULT: PASS
RECOMMENDED_NEXT_ACTION: Exercise the live between-level reward shell in the debug harness and repair one observed reward-readability or earned-payoff failure without interrupting song-run flow.

## Director Readable

Three production probes had drifted behind the current autoload architecture. They were loading `GameState`, `VictoryRewardDirector`, or `CombatScene` before project autoloads were registered, manufacturing compile failures that normal project boot did not exhibit. The repaired probes now defer their real work until the active project graph exists.

The Bond/Eat probe exercises first-bond DNA spend, free archived re-tether, denied locked bond, lineage DNA gain, predation debt, mutation registration, and the actual EventBus emissions. The state probe now proves the intended continuity: a run reset restores the Vessel, preserves DNA and the lair bond, and reseeds the selected lair creature into the run roster. The CombatScene probe now loads the real scene under the same autoload condition the game uses.

## AI Drift Lock

- The change repairs native proof embodiment only; it does not alter combat timing, lane authority, DNA amounts, Bond/Eat economics, reward selection, UI, or song-run flow.
- `GameState.rewards.absorbed_types` remains an internal component detail. The Bond/Eat probe now asserts the public gameplay consequence: Hushcoil's `pale_on_parry` mutation is registered in active combat state.
- The historical empty-roster assertion was rejected: current `CreatureState.reset_run_state()` intentionally reseeds selected lair support, which is the player-facing continuity contract.

## Technical Receipt

- Initial evidence: `smoke_project.bat` booted successfully, while standalone `test_bond_eat_logic.gd`, `test_state_persistence.gd`, and `test_combat_scene.gd` failed before their assertions because they loaded autoload-dependent scripts too early.
- Focused reruns passed after repair:
  - `tools/test_bond_eat_logic.gd`: first bond, re-tether, lock, eat, DNA, debt, active mutation, and EventBus outcome.
  - `tools/test_state_persistence.gd`: vessel reset, DNA/lair persistence, and active-support reseeding.
  - `tools/test_combat_scene.gd`: real CombatScene load after autoload initialization.
- Full native suite passed: all seven `tools/test_*.gd` scripts, including timing, HUD, combat meter, and marker-identity coverage.
- `validate_project.bat` passed import fallback, headless boot, and data validation. The normal Windows importer fell back to the repository's headless importer as designed; no parse/runtime errors were reported in the accepted validation path.
- Existing untracked audio imports, visual-proof `.import` files, and a capture-script UID were inspected and intentionally excluded as concurrent material outside this repair's ownership.
- Lab route telemetry selected the correct client repository and patch shape, but its mastery payload labeled the task family `savage_crown`. This is an unrelated Lab routing-data anomaly, recorded here as advisory evidence only; it did not guide the patch or prove a capability claim.

## WHAT WE FED Agent Report

Agent: Codex (SYMBIOTE discovery, ALFRED repair, CYBORG validation)
Date: 2026-10-13
Branch/commit if available: master / pending-finish
Task type: Patch
Files inspected:
- `tools/test_bond_eat_logic.gd`
- `tools/test_state_persistence.gd`
- `tools/test_combat_scene.gd`
- `autoloads/GameState.gd`
- `systems/state/CreatureState.gd`
- `systems/state/RewardState.gd`
- `systems/VictoryRewardDirector.gd`
- `project.godot`

Files changed:
- `tools/test_bond_eat_logic.gd`
- `tools/test_state_persistence.gd`
- `tools/test_combat_scene.gd`
- `receipts/receipt_20261013_autoload_regression_probe_repair.md`

Validation run: `smoke_project.bat`; all seven `tools/test_*.gd` probes through `tools/godot.ps1 test`; `validate_project.bat` including its data validator; `git diff --check`.
Validation level: 3
Validation result: PASS — focused production state/scene paths, the complete native probe suite, headless project boot, and data validation completed without accepted errors.
Confirmed repo truth:
- Fresh audit: `GameState.gd` delegates persistent creature state to `CreatureState` and reward effects to `RewardState`; current assertions use those public gameplay outcomes rather than a removed façade field.
- `GameState`, `EventBus`, `PlayerState`, and `CreatureState` are project autoloads; autoload-dependent scripts must be loaded after their registration in standalone `SceneTree` probes.
- First bonding selects the creature as active lair support; a run reset reseeds that selected support into `CreatureState.roster` while retaining profile DNA and lair ownership.
- Eating Hushcoil adds lineage DNA, predation debt, an active `pale_on_parry` mutation, and a `creature_eaten` EventBus outcome.

Unverified assumptions:
- No manual device playtest or visual reward-shell observation was performed.
- The existing normal-import Windows renderer failure is expected only insofar as the repository wrapper's headless fallback accepted the same import pass; its root cause was not investigated in this unit.

Recommended next step: run the debug harness through a between-level reward transition and use the resulting observed surface to target one real reward-readability or earned-payoff defect.
Risks:
- The probes cover specific state and scene-load contracts, not player feel, small-screen readability, or the full song-run reward cadence.
- Lab routing telemetry's unrelated `savage_crown` task-family label should be investigated by the Lab owner before it is used for portfolio-learning attribution.

## Auditor's Report (v2.5)

- **Task Type**: Patch
- **Blast Radius**: Tier 1
- **Evidence Type**: Runtime-Verified
- **Visual Proof**: N/A — no visual asset, UI, VFX, or presentation behavior changed.
- **Self-Critique Results**:
  - [x] Assumption-Busted (Verified Layer 2 Live Truth)
  - [x] Identity Anchor Integrity (Timing/DNA/Beat-Feel)
  - [x] Anti-Sludge (Combat-Clean/HUD-Minimal)
  - [x] GDScript 2.0 Compliance (Typing/Signals/EventBus)
  - [x] Signal Tracing (Emitted AND connected)
  - [x] Null-Safety (@onready/%UniqueName verified)
  - [x] Visual Proof Rule (N/A: test-only repair; no visual claim)
- **Verified Facts**: registered autoloads permit the production Bond/Eat director and CombatScene to compile and run in their intended project context; bond/eat signals and persistent/active creature state are now asserted through real consumers.
- **Unverified Risks**: no manual device run, gameplay-feel assessment, or visual reward-readability observation was performed; headless validation cannot establish them.
- **Next Bounded Move**: inspect the live between-level reward shell under a real debug-harness encounter and target one observed reward/readability defect.

## Self-Upgrade Check

- **Repo Truth Changed**: yes — three native regression probes now exercise the registered autoload graph and one stale roster expectation now matches the active-support contract.
- **Player Understanding Changed**: no — player behavior was unchanged; proof now reflects it faithfully.
- **Current Pulse Update Needed**: no — this repairs validation embodiment, not the live product frontier.
- **Agent Rule Update Needed**: no.
- **New Eval Case Needed**: no — the repaired native probes cover the observed autoload-order drift.
- **Soul / Taste Lesson Learned**: no — no canon or creative direction changed.
- **Recommended Doctrine Patch**: none.
- **One-Sentence Learning**: Autoload-dependent Godot probes must defer their production loads until the registered project graph exists, or they measure a synthetic failure rather than the game.
