# Sovereign Handoff (v3.4 "Absolute Purity")

Welcome to the **Sovereign Matrix**. You have been re-instantiated into the **WHAT WE FED** repo. 

## MISSION START PROTOCOL
1. **READ**: Ground yourself in the 4 Pillars of the **Sovereign Core**:
   - `docs/ai/SOVEREIGN_CORE.md` (The 5 Laws)
   - `docs/ai/ARCHETYPES.md` (Your Role)
   - `docs/ai/REPO_TRUTH_PROTOCOL.md` (Implementation Integrity)
   - `docs/ai/REPORT_CONTRACT.md` (Reporting standard v2.5)
2. **SCAN**: Run a recursive `grep` across `scenes/combat/` and `systems/` to find current implementation truth. DO NOT rely on stale context.
3. **IDENTIFY**: Use the `AI_AGENT_MANIFEST_TEMPLATE.md` to state your bounded goal.

## ARCHITECTURAL NORTH STAR: Enemy Purity
**Phase 1 COMPLETE.** `EnemyStriker` (`scenes/combat/EnemyStriker.gd`) is extracted and wired.

**Current boundary** (enforce this):
- `ZoneManager` (node: `"ZoneManager"`, script: `LaneManager.gd`) — **WHEN** and **WHO** fires. Authority budget, fire cycle, cooldown scheduling, status ownership (`_enemy_statuses`).
- `EnemyStriker` (`class_name EnemyStriker extends RefCounted`) — **HOW**. Damage scaling, speed scaling, Bloodscent, PALE flag application, telegraph profile.

**Phase 2 goal** (next): Move fire-cycle scheduling fully into per-enemy data so `ZoneManager` becomes a pure coordinator with no species knowledge. Push `cooldown_cycles`, `behaviour_tags` parsing, and fire eligibility into `EnemyStriker` or a companion `EnemyCooldownState`.

**Rule**: When adding new enemy species or attack types, extend `EnemyStriker` — do not add species logic back into `ZoneManager`.

## COMBAT TRUTH
- **360-Degree Spatial Combat**: Forget rigid lanes. Use `LaneManager.get_all_active_projectiles()` for proximity-based targeting.
- **Persistent Systems**: `RunGrowth` and `RunStats` are global **Autoloads**. They survive scene transitions.
- **Manga Monstrosity**: All visual juice MUST use the high-contrast `blood_ember` / `bone_white` / `ink_black` palette.

## Combat HUD presenter (living boundary)
HUD display and procedural widget **binding** live split between **`scenes/combat/CombatScene.gd`** (still owns layout, overlays, conductors, gameplay bridges) and **`systems/CombatHUDPresenter.gd`** (`RefCounted`).

**Contract**: After UI build, CombatScene fills **`_build_hud_contract_nodes()`** → **`CombatHUDPresenter.initialize(nodes)`**. New HUD nodes wired to the presenter **must be added there and in **`bind_nodes()`****.

**Presenter surface (extend here for HUD-only work)**: `refresh_health`/`refresh_hp`, `refresh_primary_hud_snapshot`, `refresh_progression_readouts`, `refresh_after_run_growth_exp`, `show_beat_feedback_timed`, `apply_hp_stamina_resource_bar_styles`, `apply_dna_routing_highlight`, `refresh_run_score`, `compact_hud_copy`, boss/song HUD methods, **`cleanup()`** mirrored with scene **`_exit_tree`**.

**Next bounded steps** (do not widen into combat redesign): Bind **`support_creature_portrait`** in the contract plus a compact `TextureRect` in layout; revive **`_flash_meter_shell`** if **`_combo_shell` / `_style_shell`** receive real refs; optionally extract **`_setup_ui`** into a **`Node`** sub-scene/script when presenters feel overcrowded.

## THE FINALITY RULE
Every IMPLEMENTATION turn MUST conclude with the **Auditor's Report (v2.5)**.

---
**Status: Grounding Complete. Extracting Patterns...**
