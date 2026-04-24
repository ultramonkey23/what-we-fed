# CLAUDE.md - Scenes

Scene scripts are live player-facing runtime. Preserve current boot flow and do not add broad redesign while patching local behavior.

- Inspect the `.tscn` and paired `.gd` before changing node paths or `%UniqueName` references.
- Keep input response clear and avoid active-combat interruptions.
- Prefer small scene-local changes unless signal/data ownership clearly belongs in `autoloads/`, `systems/`, or `data/`.
- After scene script edits, run `smoke_project.bat`; run `validate_project.bat` if imports, node structure, or resources changed.
