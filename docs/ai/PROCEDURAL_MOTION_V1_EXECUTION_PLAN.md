# CODEX EXECUTION PLAN: Procedural Motion v1

**To the AI Agent reading this:** 
Execute these phases strictly in order. Do not skip to Phase 3 before Phase 1 is validated. Apply GDScript 2.0 static typing `-> void` / `: int` to all methods. Adhere to the "Timing Truth" and "Combat-Clean" constraints outlined in `GEMINI.md`.

## PHASE 1: The Math & The Paint (Foundation)
**Blast Radius:** Tier 1 (New files, non-destructive)

### Task 1.1: Create `MotionJuice` (Procedural Tween Core)
**Target:** `systems/MotionJuice.gd`
**Action:** Create a new GDScript file. It must be registered as an Autoload (Node) so it can safely process global Hitstop without desyncing the `SongConductor` audio.

**Required Class Signature & Functions:**
```gdscript
extends Node
class_name ProceduralMotionDirector

# Caches active tweens to prevent memory leaks and overlapping slop
var _active_tweens: Dictionary = {}

## IMPACT LAYER
# Freezes specific visual nodes. DO NOT change Engine.time_scale (breaks audio sync).
func apply_hitstop(targets: Array[Node], duration: float = 0.05) -> void:
    pass

# Applies violently fast translation, then smooth elastic return.
func directional_recoil(target: Node2D, direction: Vector2, force: float = 30.0, recovery_time: float = 0.3) -> void:
    pass

## LIFE LAYER
# Micro-scale down on beat, smooth return. Must anchor to bottom-center.
func beat_pulse(target: CanvasItem, intensity: float = 0.02) -> void:
    pass

## TRUTH LAYER
# The Predator Snap: reverse anticipation, instant strike.
func predator_snap(target: Node2D, strike_position: Vector2, windup_time: float = 0.5) -> void:
    pass
```
*Codex Note:* Ensure `beat_pulse` checks for `is_instance_valid(target)` and stops any existing scale tweens on that specific target before applying a new one.

### Task 1.2: Create `BlackSignalCombat` Shader
**Target:** `art/vfx/black_signal_combat.gdshader`
**Action:** Create a modular Godot 4 CanvasItem shader that handles all visual state shifts without swapping single-frame assets.

**Required Uniforms:**
```glsl
shader_type canvas_item;

uniform float hit_flash_intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 hit_flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float corruption_amount : hint_range(0.0, 1.0) = 0.0;
uniform float chromatic_aberration : hint_range(0.0, 0.1) = 0.0;
```
*Codex Note:* The shader must cleanly `mix` the base texture with `hit_flash_color` based on `hit_flash_intensity`. It should offset the `R` and `B` channels horizontally based on `chromatic_aberration` for heavy hits.

---

## PHASE 2: The Rhythm Link (Integration)
**Blast Radius:** Tier 2 (Wiring into active systems)

### Task 2.1: Hook Pulse to the Conductor
**Target:** `data/EnemyTemplates.gd` (or specific enemy base scenes) AND `systems/CombatPresentationRuntime.gd`.
**Action:** Connect to `EventBus`.

**Logic to inject:**
1. Listen for the global beat signal (e.g., `EventBus.song_beat_hit` or equivalent from `SongConductor.gd`).
2. On beat down, invoke `MotionJuice.beat_pulse(self.sprite, 0.03)` for all active enemies.
3. **Guardrail:** Do NOT apply this to static HUD elements or backgrounds. Apply strictly to Enemy and Boss `Sprite2D` nodes.

### Task 2.2: Apply State Layer Shaders
**Target:** Enemy Base Scene / Visuals script.
**Action:** 
1. Assign a new `ShaderMaterial` using `black_signal_combat.gdshader` to the main enemy sprites.
2. Expose a helper function: `func flash_damage() -> void`
3. Use a `Tween` to animate the material's `hit_flash_intensity` shader parameter from `1.0` to `0.0` over `0.1` seconds.

---

## PHASE 3: The Impact Link (Execution)
**Blast Radius:** Tier 3 (Modifying core combat resolution)

### Task 3.1: Wire the Violence (Hitstop & Recoil)
**Target:** `scenes/combat/PlayerCombat.gd` & `systems/CombatImpactFeedback.gd`.
**Action:** Update the combat resolution logic to use `MotionJuice`.

**Logic to inject:**
1. Locate the exact line where damage is resolved (e.g., `on_hit_landed` or `deal_damage`).
2. Trigger Hitstop: `MotionJuice.apply_hitstop([player_sprite, enemy_sprite], 0.1)`
3. Trigger Recoil: `MotionJuice.directional_recoil(enemy_sprite, hit_direction, 40.0, 0.2)`
4. Trigger Shader Flash: Call `enemy_sprite.flash_damage()` created in Task 2.2.

### Task 3.2: Wire the Predator Snap (Enemy Attacks)
**Target:** Enemy combat state machine or attack functions.
**Action:** Replace any linear `create_tween()` movement used for enemy lunges with `MotionJuice.predator_snap()`. 

**Guardrail:** The actual damage hitbox or logical strike must register on the exact frame the `predator_snap` resolves its windup. *Do not let the visual tween desync from the logical hit frame.*

---

## EXECUTION DIRECTIVE FOR CODEX

When ready to begin, copy and paste this command back to the user or execute it directly:

> **"I am acting as the GDScript Surgeon. I will begin by executing PHASE 1, creating `systems/MotionJuice.gd` and `art/vfx/black_signal_combat.gdshader`. Once complete, I will run `validate_project.bat` before proceeding to PHASE 2."** 

### Automated Validation Checklist (Codex must verify before finalizing):
- [ ] `MotionJuice.gd` uses static typing (`-> void`, `: float`).
- [ ] Hitstop implementation does NOT touch `Engine.time_scale`.
- [ ] `black_signal_combat.gdshader` compiles without errors.
- [ ] Enemy pivot points are verified to be `Bottom Center` so scaling doesn't detach them from their lane floor.
