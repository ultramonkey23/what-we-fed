# GDScript Debug Playbook — WHAT WE FED

## 1. Blocker-First Workflow
- **Crash Localization**: Read the stack trace. Identify the exact line.
- **Minimal Fix First**: Patch the exact failure point (e.g., add null-checks, bounds checking) rather than rewriting the surrounding system.
- **Zero-Blocker Policy**: Never build features on top of a crashing or flaky foundation.

## 2. Instrument Exactly
- **Targeted Logging**: Add `print("[DEBUG] System: Event: Data")` only in the suspected failure path.
- **State Dumps**: Log the entire state of an object before the failure (e.g., `print(creature_data.to_dict())`).
- **Signal Trace**: Log when a signal is emitted AND when it is received to confirm connection integrity.
- **Cleanup**: Remove all debug logs before finalizing a fix.

## 3. Failure Categories
- **Parse Errors**: Check for missing colons, indentation issues (tabs/spaces), or mismatched brackets.
- **Null References**: Trace origin (where *should* it have been assigned?) and check Lifecycle (was it freed?).
- **Signal Bugs**: Verify `.connect()` return value. Check for double-firing (Inspector + Code).
- **State/Flow**: Verify `EventBus` spelling and `GameState` persistence.

## 4. Exact Failure Boundary
- Define exactly what works and what doesn't.
- "Projectiles don't hit" -> "Projectiles hit collision shape but `on_hit` signal is not received by `PlayerCombat.gd`."
- Narrow the search area until the bug has nowhere to hide.

## 5. Trace Logging Rules
- Use prefixes (e.g., `[COMBAT]`, `[CONDUCTOR]`, `[DNA]`) for easy filtering.
- Log timing data from `SongConductor` for rhythm-related issues.

## 6. Runtime vs Static Proof
- **Static Proof**: Code review, linting, and tracing logic paths.
- **Runtime Proof**: Verification via `debug_harness.bat` or manual play.
- **Validation**: Both are required for complex bugs. Use `GDSCRIPT_VALIDATION_TEMPLATE.md`.