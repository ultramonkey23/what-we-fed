# CLAUDE.md - Systems

Systems are shared runtime contracts. Preserve signal ownership, data ownership, and validation clarity.

- Trace both emitter and listener before changing EventBus or cross-system signals.
- Keep GDScript typed and avoid hidden global state when a state component already owns the data.
- Prefer extracting helpers only when it reduces real coupling or repeated risk.
- Validate with `smoke_project.bat` after script changes; use `validate_data.bat` when data schemas, IDs, or content lookups are affected.
