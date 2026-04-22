# GDScript Engineering Rules — WHAT WE FED (v2.0 "The Typed Edge")

## 1. GDScript 2.0 (Godot 4) Standard
- **Strict Typing**: Use `@static` typing for EVERYTHING. 
  - `func _ready() -> void:`
  - `var health: int = 100`
  - `var enemy_name: StringName = &"Ashclaw"` (Use `StringName` for IDs/Actions).
- **Signal Syntax**: Use the new Godot 4 signal syntax: `signal_name.emit(args)` instead of `emit_signal("signal_name", args)`.
- **Lambda Support**: Use anonymous functions (lambdas) for simple callbacks: `timer.timeout.connect(func(): print("Done"))`.

## 2. Resource-Based Data (The "Management-Rich" Core)
- **Data = Resources**: All creature stats, loot definitions, and song metadata MUST be `Resource` objects, not dictionaries or hardcoded vars.
- **Self-Documenting**: Resources allow the SURGEON to edit data via the Inspector, ensuring "Management-Rich" detail is easy to maintain.
- **Composition**: Use Resources to swap behaviors (e.g., an `AttackPattern` resource) instead of switching scripts.

## 3. Component-Based Architecture
- **Composition > Inheritance**: Do not create deep class trees. Use child nodes ("Components") for shared behavior (e.g., `HealthComponent`, `HitboxComponent`).
- **Accessing Components**: Use `@onready var health_comp: HealthComponent = $HealthComponent`.
- **Decoupling**: Components should communicate via signals, never by direct parent-child property mutation.

## 4. Signal-Driven Flow (The EventBus)
- **Decoupled Systems**: Systems like `CombatMeter` and `CombatAudioPlayer` must never know about each other. They communicate via the `EventBus`.
- **Boilerplate Signal Pattern**:
  ```gdscript
  # EventBus.gd
  signal creature_died(creature_data: CreatureResource)
  
  # Creature.gd
  func die():
      EventBus.creature_died.emit(self.data)
  ```

## 5. Optimization & Performance
- **Physics vs Process**: Use `_physics_process` for anything affecting movement or collision. Use `_process` for UI and visual-only updates.
- **Tweening**: Use `create_tween()` for all UI animations. Avoid `AnimationPlayer` for simple property shifts to keep the "Combat-Clean" feel.

## 6. Surgical Mutation Checklist
Before a SURGEON applies a patch, the AUDITOR checks for:
- [ ] Is it typed?
- [ ] Are signals used for cross-system talk?
- [ ] Is it a "Component" or a "Blob"? (Blobs are rejected).
- [ ] Does it use `Resource` for its configuration?

## 7. Anti-Sludge / Anti-Drift
- **Timing Honesty**: Any script touching combat must respect the `SongConductor`'s pulse.
- **Lane Integrity**: Scripts must never move an entity outside of Lanes 0, 1, or 2 without a Tier 3 BRA approval.
- **No Hidden Logic**: Logic belongs in `.gd` files. `.tscn` files are for structure only.
