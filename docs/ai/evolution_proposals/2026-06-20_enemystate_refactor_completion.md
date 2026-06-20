# Proposal: Complete the EnemyState Struct Refactor (commit 6ac488b)

## Problem Observed

Commit `6ac488b — refactor(combat): collapse parallel enemy dicts into EnemyState struct` was committed without validation. The refactor was intended to replace five parallel dictionaries on `ZoneManager` (`_enemies`, `_enemy_positions`, `_orbit_angles`, `_orbit_radius_offsets`, `_strikers`) with a single `_enemy_states: Dictionary` of `EnemyState` RefCounted structs.

The refactor was applied via a regex-style transformation that left two classes of breakage:

1. **Parse-blocking malformed expressions** — multi-key subscripts and unbalanced parentheses where the regex turned `dict.get(id, default)` into invalid GDScript. Fixed in this turn at:
   - `scenes/combat/ZoneManager.gd:337` (was `_enemy_states[id, _projectile_scene].projectile_scene if _enemy_states.has(id, _projectile_scene)`)
   - `scenes/combat/ZoneManager.gd:672` (was `_enemy_states[id, _rng.randf_range(0.0, TAU].orbit_angle if _enemy_states.has(id, _rng.randf_range(0.0, TAU)`)

2. **Identifier references to retired fields** — the parallel dicts were removed from `ZoneManager` but multiple call sites still reference them by name. Godot 4's static parser rejects the script:

   ```
   ZoneManager.gd:52  — _locom_director.init(self, _enemies, _enemy_positions, _orbit_angles, _orbit_radius_offsets, _strikers)
   ZoneManager.gd:124 — _get_striker_visual_offset_for_angle(angle)  (function name does not exist; closest is _assign_striker_visual_offset_for_angle)
   ZoneManager.gd:152 — _status_director.tick_song_beat(_enemies, ...)
   ZoneManager.gd:221 — return _enemies
   ZoneManager.gd:234 — return _strikers.size()
   ZoneManager.gd:485 — return _strikers
   ZoneManager.gd:685 — if _enemy_positions.has(id):
   ZoneManager.gd:762 — for enemy_id in _enemies.keys():
   ```

3. **Downstream director still holds the legacy dicts as shared mutable references**:
   `systems/CreatureLocomotionDirector.gd:53-57, 66-79` declares the 5 retired fields and accepts them at `init()`. The body reads and writes to them on every frame (`_step_all_enemies`, `_get_profile`, etc., ~21 references total).

4. **Construction gap**: `spawn_enemy_at_angle()` (ZoneManager.gd:318) writes to `_enemy_states[id].population_data` at line 333 without ever constructing the `EnemyState` instance for that `id`. The parallel `start_combat()` flow at line 138 does call `EnemyState.new()` + `state.setup(...)` + `_enemy_states[id] = state`; that construction is missing from the angle-spawn path.

## Evidence

- Validate run log (current branch, post-parse-fix): `godot-import.log` shows 8 "Identifier not declared" parse errors and 1 "Function not found" parse error in `ZoneManager.gd`, all consequences of the incomplete refactor.
- Smoke still passes (`SMOKE OK`) — autoloads load fine; combat scene never instantiates during smoke, so the rot is hidden.
- Pattern at `ZoneManager.gd:116` (in `start_combat()`) is the correct working idiom and was the template used to fix the two parse errors in this turn.
- Git: `git log -L 337,337:scenes/combat/ZoneManager.gd` shows commit `6ac488b` as the source of the regression. The original line at commit `833e097` was:
  `so.setup(enemy, _enemy_projectile_scenes.get(id, _projectile_scene) as PackedScene)` — semantically meaning "use cached scene for this id, fallback to the default projectile scene."

## Affected Files / Systems

- `scenes/combat/ZoneManager.gd` (protected system)
- `systems/CreatureLocomotionDirector.gd`
- `systems/StatusDirector.gd` (signature of `tick_song_beat(enemies, damage_callback)`)
- Possibly `systems/CombatFireDirector.gd` (calls `_zone_manager.get_all_strikers()` / `get_all_enemies()`)

## Proposed Change

**Smallest controlled refactor that completes the original intent and restores parse validity:**

1. **`CreatureLocomotionDirector.init` signature change**: replace the five dict parameters with a single `enemy_states: Dictionary` reference. Internally, drop the five private dicts and read/write through `_enemy_states[id].position`, `.orbit_angle`, `.orbit_radius_offset`, `.population_data`, `.striker_data`.

2. **`ZoneManager` projection helpers** (read-only views, no parallel storage):
   ```gdscript
   func get_all_enemies() -> Dictionary:
       var out: Dictionary = {}
       for id in _enemy_states:
           out[id] = _enemy_states[id].population_data
       return out

   func get_all_strikers() -> Dictionary:
       var out: Dictionary = {}
       for id in _enemy_states:
           if not _enemy_states[id].striker_data.is_empty():
               out[id] = _enemy_states[id].striker_data
       return out

   func alive_striker_count() -> int:
       var n: int = 0
       for id in _enemy_states:
           if not _enemy_states[id].striker_data.is_empty():
               n += 1
       return n
   ```

3. **Identifier substitutions in `ZoneManager`** (mechanical, scoped to specific lines):
   - L52: `_locom_director.init(self, _enemy_states)`
   - L152: rewrite to project enemies dict for `tick_song_beat` (or change `tick_song_beat` to accept `_enemy_states`)
   - L685: `_enemy_states.has(id)`
   - L762: `_enemy_states.keys()`

4. **Function rename audit**: `ZoneManager.gd:124` calls `_get_striker_visual_offset_for_angle(angle)` returning a `Vector2`. Either:
   - (a) revive the getter from pre-refactor git history, or
   - (b) update line 124 to compute the offset inline using the same logic as `_assign_striker_visual_offset_for_angle` (line 699) without the side effect.

5. **`spawn_enemy_at_angle` construction**: insert the missing `var state := EnemyState.new(); state.setup(...); _enemy_states[id] = state` block before any access to `_enemy_states[id].*`.

## Risk

- **Combat is the soul system** — incomplete refactor leaves combat literally non-loadable. Completing it is **higher** value than leaving it half-done.
- The Sequential Mutation Law (Sovereign Law 3) means this is one cohesive turn's worth of work, not a partial sweep across sessions.
- Test coverage for combat boot is currently nonexistent at static-validate level (smoke does not exercise the combat scene). A regression here would not be caught by `smoke_project.bat`. Recommend the implementer run the editor and load `CombatScene.tscn` interactively.

## Validation Plan

1. **Tier 2 (Static)** — `validate_project.bat` must show zero parse errors after the refactor.
2. **Tier 3 (Runtime)** — boot the project, enter combat through TitleScreen → LairScene → RouteScene → CombatScene flow, verify a regular level can start and at least one enemy fires + can be parried/dodged.
3. **Tier 4 (Playtest)** — short run through 2-3 levels; confirm orbit movement, flanker behavior, and projectile spawn match pre-refactor feel.
4. **Pre-Flight Signal Grep** before mutating: search the repo for callers of any function whose signature changes (`get_all_enemies`, `get_all_strikers`, `alive_striker_count`, `tick_song_beat`).

## Rollback Plan

- All changes are confined to two files (`ZoneManager.gd`, `CreatureLocomotionDirector.gd`) plus potentially `StatusDirector.gd`. A single `git revert` of the implementation commit restores the partially-broken state.
- The "partially-broken state" itself is already unable to load combat, so rollback returns to the same non-functional baseline — no regression risk.

## Approval Required

Human (Cody) — touches protected systems (`ZoneManager.gd`) and a combat-spine director. Not a doctrine or canon change.

## Companion Receipts

Independent of this proposal, the current turn shipped two safe Tier 0 wins that do not depend on the refactor and need no approval:

- `systems/CombatRunDirector.gd` — removed `_test_collar_mechanics()` test shim that ran on every `initialize_run()` in production, printing 7 lines and mutating `equipped_collar_id` to `"iron_doctrine"` before restoring it. Real production hygiene bug from commit f5d6428 lineage area.
- `systems/CombatFireDirector.gd:181` — typed `var candidates: Array = []` as `Array[Dictionary]` (Sovereign Law 7 Typed Instruction Mandate).
- `scenes/combat/ZoneManager.gd:337, :672` — fixed the two malformed multi-key subscripts to the correct `_enemy_states[id].X if _enemy_states.has(id) else <fallback>` idiom matching line 116. These edits do not regress the file (it was already failing to parse) and they are required as a prerequisite for any further work in those functions.
