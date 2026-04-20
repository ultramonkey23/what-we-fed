# Godot Scene Wiring Checklist

Before considering a script complete, AI agents must mentally or physically verify the following scene integration points to prevent breaking the game runtime.

## 1. Node Path Verification
- [ ] **Are `@onready` paths valid?** Check the corresponding `.tscn` file to ensure the hierarchy matches `$Child/Grandchild`.
- [ ] **Are `get_node()` calls safe?** Are they wrapped in null-checks or guaranteed by the scene structure?
- [ ] **Did you rename a node?** If a script renames a node, ensure all referencing scripts and `.tscn` files are updated.

## 2. Scene Tree Assumptions
- [ ] **Where does this live?** Is this script attached to the Root node, or a deeply nested child? This affects `owner` and `get_parent()` logic.
- [ ] **Instantiation:** Is this scene instantiated dynamically via `load().instantiate()`? If so, does it rely on `_ready()` being called immediately? (It doesn't happen until `add_child()`).

## 3. Signal Wiring Verification
- [ ] **Inspector Connections:** Does the `.tscn` file define connections? If you renamed a handler method in code (e.g., `_on_button_pressed`), did you update the `.tscn`?
- [ ] **Code Connections:** Are `.connect()` calls passing the correct number of bound arguments?
- [ ] **EventBus:** If listening to `EventBus`, does the signal exist in `autoloads/EventBus.gd`?

## 4. Exported Variables & Inspector Overrides
- [ ] **Type Mismatches:** If you changed `@export var speed: int` to `@export var speed: float`, verify the `.tscn` doesn't have a conflicting override.
- [ ] **Resource Assignments:** Does the script expect an `@export var resource: Resource` to be pre-filled? If adding a new one, alert the human developer to fill it in the editor.

## 5. Input Action Verification
- [ ] **Action Names:** Are `Input.is_action_just_pressed("string")` strings verified against `project.godot`? (Do not assume "move_left" or "attack" exist without checking).

## 6. Autoload Dependencies
- [ ] **Existence:** Are `GameState`, `EventBus`, or `DevHarness` calls accurate to their defined APIs?
- [ ] **Initialization Order:** Does the script assume `GameState` data is loaded before its own `_ready()` fires?

## 7. Verification Before Declaring "Done"
- [ ] **Parse OK:** The script must contain zero syntax or typing errors.
- [ ] **Headless Run:** `validate_project.bat` should pass without scene instantiation crashes.
- [ ] **Integration Holds:** The change does not orphan existing scene logic.