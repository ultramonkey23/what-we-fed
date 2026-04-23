# What We Fed Repo System Map

This is the fast ownership map for Codex, Claude Code, and human terminal work.

Use [PROJECT_SETUP_AND_VALIDATION.md](PROJECT_SETUP_AND_VALIDATION.md) first for launch and validation.

## Runtime Flow

Boot flow:
- `project.godot` -> `res://scenes/ui/TitleScreen.tscn`
- `scenes/ui/TitleScreen.gd` -> sends the player into `LairScene`
- `scenes/ui/LairScene.gd` -> selects active lair creature
- `scenes/ui/RouteScene.gd` -> selects active region
- `scenes/combat/CombatScene.gd` -> owns the live combat run

Autoloads:
- `autoloads/EventBus.gd`: cross-system signal hub
- `autoloads/GameState.gd`: persistent state orchestrator; delegates to modular components in `systems/state/` (Player, Creature, Reward, WorldFate, Run)

Combat owners:
- `scenes/combat/CombatScene.gd`: arena setup, encounter flow, song-mode orchestration, boss flow, reward shell
- `scenes/combat/PlayerCombat.gd`: player input resolution, attack/parry/dodge damage, death path
- `scenes/combat/LaneManager.gd`: lane enemy occupancy and spawn/respawn timing
- `systems/CombatMeter.gd`: combo, style, stamina, ultimate, tier state
- `systems/CombatImpactFeedback.gd`: impact/readability helpers
- `systems/CombatPresentationRuntime.gd`: presentation helper layer for combat
- `systems/CombatTransitionState.gd`: small transition-state helper

Song / boss pressure:
- `systems/SongConductor.gd`: beat and section timing, beat-quality checks
- `systems/EncounterIdentityRuntime.gd`: region/encounter identity layer
- `data/RegionSongContent.gd`: region song routing and phase identity
- `data/song_maps/*.gd`: authored song timing maps

Growth / reward:
- `systems/RunGrowth.gd`: growth orchestrator; delegates to modular managers in `systems/growth/` (Progression, Tendency, Support)
- `systems/PerformanceRewardDirector.gd`: performance reward offers and claims
- `systems/PotentialGate.gd`: layered Potential ceiling resolver (creature/world/run)
- `data/RunGrowthContent.gd`: growth tuning and effects
- `data/PerformanceRewardContent.gd`: reward data

Content / tuning:
- `data/CombatContent.gd`: encounter and creature combat content
- `data/RouteContent.gd`: route-region data
- `data/AudioContent.gd`: audio paths and music references
- `data/SongLibraryContent.gd`: centralized song library and metadata
- `data/EncounterIdentityContent.gd`: region encounter identity data

Visual / UI style:
- `systems/UIStyle.gd`: shared HUD and text styling
- `assets/`: textures, portraits, backgrounds, audio assets
- `resources/`: reusable resource-side content

## Tooling Entry Points

Repo-local Godot wrappers:
- `run_project.bat`: launch the game
- `debug_harness.bat`: launch the dev-only combat harness
- `smoke_project.bat`: fast headless boot check
- `validate_project.bat`: import pass plus headless smoke
- `editor_project.bat`: open Godot editor
- `resolve_godot.bat`: print resolved Godot executable
- `tools/godot.ps1`: shared wrapper behind all repo-local commands

Dev harness:
- `scenes/dev/DebugBootScene.gd`: preset selector for fast combat-state boot
- `autoloads/DevHarness.gd`: inert request holder consumed only by explicit harness runs

Demo-only (not in live combat graph):
- `examples/demo_encounter_stack/*.gd`: procedural encounter + mutation demo used by `examples/NewSystemsDemo.gd` only; `CombatScene` uses `EncounterIdentityRuntime` + `CombatContent` instead.
- Debug harness preset `generated_boss` (`debug_generated_boss_encounter` on `DevHarness` request): `CombatScene` runtime-loads `EncounterGenerator` and normalizes via `systems/GeneratedEncounterAdapter.gd` into `_load_encounter_payload` (authored boss remains default).

Repo-local state:
- `.godot-cli/logs/`: Godot logs for run, smoke, validate, import, editor
- `.godot-cli/AppData/`: repo-local Godot writable state

## Source Truth

Read these before making scope assumptions:
- `PROJECT_SETUP_AND_VALIDATION.md`: repo workflow entrypoint
- `docs/GAME_SPINE.md`: current live-build identity
- `docs/POTENTIAL_SYSTEM_V1.md`: Potential architecture and v1 implementation contract
- `docs/DEMO_MILESTONE_LADDER.md`: what the current build has already proven
- `docs/NEXT_PHASE_PLAN.md`: near-term implementation direction
- `docs/WHAT_WE_FED_FINAL_GAME_SCOPE_CANON_FLAGSHIP.md`: larger flagship canon
- `docs/THE_HOLLOW_EGG_KAIJU_ASCENSION_CANON.md`: later-scope world-state canon
- `docs/GAME_SOUL_AND_CORE_FANTASY.md`: core fantasy guardrail
- `docs/SONG_LEVEL_STRUCTURE.md`: song/runtime structure

## Practical Routing

If the task is about:
- boot, validation, editor launch, or logs -> start at `tools/godot.ps1`
- fast combat-state iteration -> start at `debug_harness.bat`, then `scenes/dev/DebugBootScene.gd`
- startup failure or scene routing -> start at `project.godot`, then `scenes/ui/TitleScreen.gd`
- combat feel or encounter flow -> start at `scenes/combat/CombatScene.gd`
- player action correctness -> start at `scenes/combat/PlayerCombat.gd`
- combo/style/stamina logic -> start at `systems/CombatMeter.gd`
- growth, bonded support, or run stat progression -> start at `systems/RunGrowth.gd`
- Potential ceilings or encounter grade caps -> start at `systems/PotentialGate.gd`, then `scenes/combat/CombatScene.gd`, then `systems/EncounterIdentityRuntime.gd`
- beat timing or phase changes -> start at `systems/SongConductor.gd`
- content tuning or adding variants -> start in `data/`
- cross-system coordination -> check `autoloads/EventBus.gd`

## Fast Validation Path

Use this sequence unless the task needs deeper runtime confirmation:
1. `smoke_project.bat`
2. `validate_project.bat` if imports/assets changed
3. `run_project.bat` only when interactive confirmation matters

Do not claim gameplay validation from smoke or validate alone.
