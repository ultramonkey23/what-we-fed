# WHAT WE FED — PROJECT INSTRUCTIONS

## Project Identity
WHAT WE FED is an **RPG roguelite first**. It is a dark, oppressive, premium-feeling creature progression game where realtime lane-timing combat is the signature expression layer for species-specific DNA growth, Bond vs Eat tension, and the fantasy of starting weak and becoming feared. It is **not** a generic survivor clone, creature collector, ranch-first sim, or roguelite soup.

## The Locked Core (Do Not Break)
- **Timing Truth**: Rhythm and input must be honest. No floaty timing.
- **Lane Readability**: Players must clearly see what is coming in which lane. No VFX clutter.
- **DNA Economy**: DNA is species-specific. Predation is the engine.
- **Bond vs Eat**: This choice must remain a meaningful identity split with consequences.
- **No-Pause Flow**: The game is a realtime song-run. Avoid stop-start menu interruptions.
- **Start Weak, Become Feared**: Progression must feel like becoming a monster.

## Authority Hierarchy
1. **Live Build Truth**: What is currently in the code (e.g., `scenes/combat/CombatScene.gd`).
2. **Current Runtime Behavior**: How the game actually runs (use `run_project.bat`).
3. **Current Task Constraints**: The specific goal provided by the user.
4. **Long-Term Direction**: `docs/NEXT_PHASE_PLAN.md` and `docs/GAME_SPINE.md`.
5. **Dream Scope**: `docs/WHAT_WE_FED_FINAL_GAME_SCOPE_CANON_FLAGSHIP.md` (Handle with caution; deferred unless specified).

## Anti-Drift Bans
- **NO** generic survivor/bullet-heaven mechanics (unless they fit the lane/timing core).
- **NO** generic RPG stat sludge or flat spreadsheet progression.
- **NO** sterile/safe UI. The game has "teeth."
- **NO** speculative automation or machine-wide dependencies. Use repo-local tools.

## Coding Behavior
- **Surgical Passes**: Prefer bounded implementation over giant rewrites.
- **Root Cause Fixes**: Fix the engine, don't just paint over the bug.
- **Preserve Readability**: HUD clarity and lane honesty always beat visual spectacle.
- **Event-Driven**: Use `EventBus.gd` for cross-system communication.
- **State Integrity**: `GameState.gd` owns persistence; `systems/RunGrowth.gd` owns run-local growth.

## Validation Protocol
**EVERY** code change that affects runtime behavior must be validated.
1. `smoke_project.bat`: Fast check for parse errors and boot crashes.
2. `validate_project.bat`: Full import and headless validation (use if assets/data changed).
3. `debug_harness.bat`: Use for rapid combat-specific testing.
4. **Manual Run**: `run_project.bat` is required for feel, readability, and timing verification.

**Reporting Rule**: Always state exactly what was verified (e.g., "Verified with smoke test; did not launch game") and what remains unverified (e.g., "Timing feel not manually tested").

## Bottleneck Files (Careful Edits)
- `scenes/combat/CombatScene.gd`: Orchestration hub.
- `scenes/combat/PlayerCombat.gd`: Input/Combat resolution.
- `systems/SongConductor.gd`: The master clock.
- `autoloads/EventBus.gd`: The system glue.
- `autoloads/GameState.gd`: The persistence heart.

## AI Operating Procedures
For detailed implementation rules, debugging playbooks, and self-improvement protocols, refer to:
- `docs/ai/GDSCRIPT_ENGINEERING_RULES.md`
- `docs/ai/GODOT_SCENE_WIRING_CHECKLIST.md`
- `docs/ai/GDSCRIPT_VALIDATION_TEMPLATE.md`
- `docs/ai/AI_SELF_IMPROVEMENT_PROTOCOL.md`

---
*Refer to nested GEMINI.md files in `scenes/combat/`, `systems/`, and `data/` for local rules.*
