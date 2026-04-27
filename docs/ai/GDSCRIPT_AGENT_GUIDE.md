# WHAT WE FED — GDSCRIPT AGENT GUIDE

## 1. Purpose
This guide defines the standard for writing safe, repo-fit GDScript for WHAT WE FED.

## 2. Core Rule
**Do not write generic GDScript.** 
First scan the repo to match local style, identify system ownership, and apply the smallest surgical change possible.

## 3. Required Before Editing `.gd`
Before modifying code, identify:
- **System Ownership**: Which autoload or director owns this logic?
- **Event/Signal Context**: Does this trigger an `EventBus` signal?
- **Data Ownership**: Is this a hardcoded value that belongs in `data/`?
- **UID Impact**: Does this file have a linked `.uid` file that must be respected?
- **Validation Path**: How do you verify this change (e.g., `validate_project.bat`)?

## 4. Typing Rules
Prefer typed GDScript for new or edited code:
- Annotate function parameters and return types (e.g., `func process_dna(species_id: String) -> void:`).
- Use typed variables where clarity improves readability.
- Do not perform mass conversions of old, untyped files.

## 5. Function Rules
- Keep functions small and focused.
- Name functions by gameplay intent (e.g., `_resolve_combat_impact` not `_do_stuff`).
- Do not create broad utility functions unless reused across multiple systems.

## 6. Signal Rules
- Respect existing `EventBus` signal contracts. 
- **NEVER** change signal signatures without updating all listeners.
- New signals require documented emitter, payload, and owner.
- **Lifecycle Mandatory**: Every signal connected in `_ready()` MUST be disconnected in `_exit_tree()` to prevent memory leaks.

## 7. Node / Scene Rules
- Do not edit `.tscn` files unless explicitly required for the task.
- Use typed `@onready` references for nodes.
- Guard optional node access (`if node: ...`).
- If editing a script attached to a scene, check for linked `.uid` files to ensure Godot resource integrity.

## 8. Autoload Rules
- `GameState.gd`: Persistent/global state only.
- `EventBus.gd`: Cross-system communication only.
- Do not add new autoloads or global variables without explicit approval.

## 9. Data / Export Rules
- **Data > Code**: Move tuning variables to `data/` classes.
- Use `export` only for editor-tunable parameters.
- Do not hardcode creature/item IDs or balance constants.

## 10. Error / Guard Rules
- Use defensive checks for all optional data/resources.
- Report missing dependencies via `DebugTrace` or clear errors.
- Do not swallow errors; do not spam logs during combat.

## 11. Combat-Specific GDScript Rules
Combat logic is fragile. **NEVER** modify without extreme care:
- Timing windows
- Player action resolution
- Lane/projectile resolution
- Combat HUD feedback (Timing Truth compliance)

## 12. Style Rules
- Match naming and spacing of the file being edited.
- Prefer readability over cleverness.
- No mass-reformatting; no cleanup outside the feature's scope.

## 13. Validation Checklist
- [ ] `git status --short` (review changes)
- [ ] `validate_project.bat` (parse errors)
- [ ] `smoke_project.bat` (functional baseline)
- [ ] `validate_data.bat` (if `data/` touched)
- [ ] Manual playtest (required for input/rhythm/HUD/combat feel)

## 14. Mandatory Report Section
Any report touching `.gd` must include:
```
GDScript quality decision:
- Existing style matched:
- Types added:
- Signals changed: (yes/no)
- Signals disconnected in _exit_tree: (yes/no)
- Node paths changed: (yes/no)
- Autoload/global state changed: (yes/no)
- Data ownership respected:
- UID integrity maintained:
- Validation run:
- Remaining GDScript risks:
```

## 15. Stop Conditions
Stop and report if the change requires:
- Broad architectural rewrite
- `project.godot` changes
- New global state/autoloads
- Combat loop/timing modification without approval
- Potential for memory leaks (missing disconnects)
- Breaking UID resource mapping
