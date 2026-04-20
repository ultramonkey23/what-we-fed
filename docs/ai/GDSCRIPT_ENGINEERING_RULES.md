# GDScript Engineering Rules — WHAT WE FED

## 1. Typed GDScript Discipline
- **Mandatory Types**: All variables, function parameters, and return values must be explicitly typed.
- **Inference**: Use `:=` for type inference only when the type is obvious (e.g., `var health := 100`).
- **No `variant`**: Avoid using untyped variables or generic `Variant` unless absolutely necessary for engine compatibility.
- **Why**: Reduces runtime errors and clearly defines data contracts for future agents.

## 2. Node Path Discipline
- **Unique Names**: Prefer `%UniqueName` for accessing specific UI or child nodes within a scene.
- **Exported Nodes**: Use `@export var target_node: Node2D` for cross-node references instead of hardcoded strings.
- **Safety**: Always check `if target_node:` or `is_instance_valid(target_node)` before accessing methods or properties.
- **Anti-Assumption**: Do not hallucinate Godot nodes or input actions. Grep `project.godot` or inspect `.tscn` files first.

## 3. Signal Discipline
- **EventBus First**: Cross-system communication MUST use `EventBus.gd` strictly for decoupled communication.
- **Local Signals**: Use local signals only for internal child-parent communication within a scene.
- **Connection**: Prefer connecting signals in code via `.connect()` for traceability.
- **Disconnection**: Ensure signals are disconnected or nodes are freed correctly to avoid memory leaks or "signal to dead object" errors.

## 4. Scene Wiring Discipline
- **Logic in Scripts**: Keep logic in `.gd` files, not in `.tscn` animation tracks or complex inspector overrides.
- **Initialization**: Use `_ready()` for initial wiring and `_enter_tree()` only when necessary for early setup.
- **Order of Operations**:
  1. `class_name` / `extends`
  2. `# signals` -> `# enums` -> `# constants` -> `# exports`
  3. `# public variables` -> `# private variables` -> `@onready variables`
  4. `_init()`, `_ready()`, `_process()`, etc.
  5. Public methods -> Private methods (`_`) -> Signal handlers

## 5. Architectural Integrity
- **Composition over Inheritance**: Prefer adding child nodes with specific behaviors over deep class hierarchies.
- **Single Responsibility**: One script = one primary job. If a script exceeds 300 lines, consider extracting a helper or component.
- **Data vs Behavior**: Keep creature stats and definitions in `data/`, behavior logic in `scenes/combat/`.

## 6. Minimal Change Philosophy
- **Surgical Edits**: Touch only the lines necessary for the task. Do not rewrite a 500-line script to fix a 2-line bug.
- **No Vanity Refactors**: Do not reformat code or change naming conventions outside the specific task scope.
- **Comment Intent**: If a change is subtle (e.g., a timing adjustment), comment *why* it was changed, not just *what* changed.

## 7. Anti-Drift: WHAT WE FED Identity
- **No Generic Mechanics**: No survivor-like auto-aim, roguelite stat-sludge, or flat spreadsheet-RPG progression that weakens creature identity.
- **No Clutter**: No screen-shake or particle spam that obscures lanes 0, 1, and 2.
- **Truthful Timing**: Do not decouple visual feedback from the `SongConductor`'s rhythm.
