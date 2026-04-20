# AGENTS — WHAT WE FED REPO CONTRACT

## 1. Universal Agent Mandate
This repository is a high-precision, identity-locked project. All agents MUST prioritize **Repo Truth** over generic AI patterns.

### Authority Hierarchy
1. **Live Build Truth**: `project.godot` and `.gd` files.
2. **Current Runtime Behavior**: `run_project.bat` results.
3. **Local Mandates**: `GEMINI.md` (root, `scenes/combat/`, `systems/`, `data/`).
4. **Agent Guidelines**: This file and `docs/ai/*.md`.

## 2. Project Identity (Locked Core)
- **Timing Truth**: Master clock is `systems/SongConductor.gd`. Rhythm/input must be honest.
- **Lane Readability**: Lanes 0–2 must stay readable. No VFX clutter or readability-breaking shake.
- **DNA Economy**: Predation is the engine. DNA is species-specific.
- **Bond vs Eat**: Meaningful split with consequences.
- **No-Pause In Active Levels**: During a regular or boss fight, combat stays real-time with honest timing (no mid-fight pause-the-song). **Between** levels, menus for rewards and inventory/resource are **intended** run pacing—not “menu creep” if they stay sharp and RPG-readable.
- **Start Weak, Become Feared**: Progression is becoming a monster.

## 3. Anti-Drift Bans
- **NO** generic survivor/bullet-heaven framing (auto-aim, meaningless XP ladders).
- **NO** stat spreadsheet sludge (empty +1% churn).
- **NO** architecture-cleanup theater. Refactor only if proven blocker or explicitly requested.
- **NO** hidden cross-cutting magic. Prefer explicit signals and clear ownership (`REPO_SYSTEM_MAP.md`).

## 4. Operational Workflow
1. **Research**: Read the runtime owner, then `EventBus.gd`, then relevant `data/*` content.
2. **Strategy**: One bounded move; separate live build (`docs/GAME_SPINE.md`, `docs/NEXT_PHASE_PLAN.md`) from deferred flagship canon.
3. **Execution**: Surgical GDScript; preserve typing and signal contracts.
4. **Validation**: See §7. State what was **not** verified.

## 5. Implementation Standards
- **Surgical Passes**: Minimal diffs; do not reformat unrelated code.
- **Typed GDScript**: Explicit types; avoid unnecessary `Variant`.
- **EventBus**: Cross-system coordination through `autoloads/EventBus.gd`.
- **Scenes**: Use Godot `%UniqueName` where the project already does for stable node paths.

## 6. Communication Rule
- One-sentence intent before multi-file edits.
- A change that affects runtime is incomplete without the validation tier in §7 (or an explicit reason why not run).

## 7. Validation (repo root = `what-we-fed/`)
Run from the folder that contains `project.godot`:
- **`smoke_project.bat`**: default after GDScript changes (fast headless boot).
- **`validate_project.bat`**: when imports/assets/data files likely affect load.
- **`debug_harness.bat`**: fast combat harness; does **not** replace full Title→Combat flow checks.
- **`run_project.bat`**: required for feel, timing, HUD readability.

Deep rules: `PROJECT_SETUP_AND_VALIDATION.md`, `docs/ai/VALIDATION_STANDARD.md`, `docs/ai/GDSCRIPT_ENGINEERING_RULES.md`.  
(If a doc still mentions `GDSCRIPT_VALIDATION_TEMPLATE.md`, prefer `docs/ai/VALIDATION_STANDARD.md` until the template file exists.)

## 8. Cursor / Session Grounding
- **Open the workspace at `what-we-fed/`** when working on the game so `AGENTS.md`, `.cursor/rules/`, and `*.bat` paths align.
- **Read first on unfamiliar tasks**: `PROJECT_SETUP_AND_VALIDATION.md`, `REPO_SYSTEM_MAP.md`, then the file you will edit.
- **Confirm with the user before**: multi-file refactors, global renames, project setting overhauls, or changes that alter beat/timing contracts across systems.

## 9. Hotpath Files (extra care; ask before broad edits)
`scenes/combat/CombatScene.gd`, `scenes/combat/PlayerCombat.gd`, `systems/SongConductor.gd`, `systems/CombatMeter.gd`, `autoloads/EventBus.gd`, `autoloads/GameState.gd`.
