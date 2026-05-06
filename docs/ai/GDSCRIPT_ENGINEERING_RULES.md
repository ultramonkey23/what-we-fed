# GDScript Engineering Rules — WHAT WE FED (v3.0 "Sovereign Optimization")

## 1. GDScript 4.3+ Standard (The "Typed Instruction" Optimization)
- **Mandatory Static Typing**: Use explicit typing for EVERYTHING. The Godot 4 VM uses static types to bypass hash-map lookups.
  - `func _ready() -> void:`
  - `var health: int = 100`
  - `var enemy_name: StringName = &"Ashclaw"` (Use `StringName` with `&` for all IDs, Actions, and Signals).
- **Typed Arrays**: Use `Array[Type]` instead of `Array`. This allows for contiguous memory and 2x-5x faster iteration in loops.
- **Signal Syntax**: Use functional syntax: `signal_name.connect(_on_callback)`. Never use string-based `connect("name", ...)`.

## 2. Resource-Based Data (The "Management-Rich" Core)
- **Data = Resources**: All creature stats, loot definitions, and song metadata MUST be `Resource` objects.
- **Strict Data Integrity**: Use `@export` with typed variables in Resources to ensure the Inspector validates the data.
- **Composition**: Prefer Resources over class inheritance for behavior swaps.

## 3. Component-Based Architecture
- **Composition > Inheritance**: Use child nodes ("Components") for shared behavior (e.g., `HealthComponent`, `HitboxComponent`).
- **Caching**: Always cache component references in `@onready var`. Avoid `$` or `get_node` in high-frequency loops (`_process`).

## 4. Signal-Driven Flow (The EventBus)
- **Typed Signals**: Signals in `EventBus.gd` should have typed arguments to maintain the optimization chain.
  - `signal creature_died(creature_data: CreatureResource)`
- **Decoupling**: High-level systems (Combat, UI, Audio) must communicate via `EventBus` signals only.

## 5. Optimization & Performance
- **WorkerThreadPool**: Use `WorkerThreadPool.add_task()` for heavy calculations (e.g., pathfinding, complex data processing) to avoid main-thread stutters.
- **Distance Squared**: Use `distance_to_squared()` instead of `distance_to()` for range comparisons to avoid costly square root operations.
- **Node Pooling**: For high-volume entities (bullets, particles), use a Node Pool instead of frequent `instantiate()` and `queue_free()`.

## 6. Strict Linting Protocol
Enable these in **Project Settings > Debug > GDScript**:
- **Untyped Declaration**: Error
- **Unsafe Method Access**: Error
- **Inferred Declaration**: Warn

## 7. Surgical Mutation Checklist
- [ ] **Typed Everything**: Are all variables, parameters, and return types explicit?
- [ ] **Typed Arrays**: Are all arrays defined as `Array[Type]`?
- [ ] **StringName Usage**: Are signals and keys using `&"name"`?
- [ ] **Signal Integrity**: Is functional signal syntax used?
- [ ] **No Sludge**: Does it respect `SongConductor`'s pulse and the 0.14s buffer?
