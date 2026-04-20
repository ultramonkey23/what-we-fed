# BUGFIX WORKFLOW — WHAT WE FED

## 1. Blocker First
- Identify the exact line or condition causing the failure.
- Do not attempt broad refactors or cleanup while a crash or blocker is active.
- Fix the blocker minimally and verify immediately.

## 2. Inspect Exact Path
- Read the entire file and its related signal connections before editing.
- Trace the data flow from origin to failure point.
- Avoid assumptions about state. Use instrumentation (logs) if uncertain.

## 3. Smallest Safe Fix
- Apply the minimal change required to resolve the bug.
- Prefer explicit null-checks and type guards over "magic" fixes.
- If the fix requires architectural changes, escalate to a planning phase first.

## 4. Bounded Cleanup
- Cleanup only the code directly related to the fix.
- Do not perform "vanity cleanup" on unrelated methods or files.
- Ensure the cleanup does not introduce new risks.

## 5. Avoid Speculative Patching
- Do not add "just-in-case" error handling that masks underlying logic errors.
- Fix the root cause, not the symptom.
- If the root cause is unclear, use the `GDSCRIPT_DEBUG_PLAYBOOK.md` to localize it.

## 6. Verification
- Use `smoke_project.bat` for parse errors.
- Use `debug_harness.bat` for runtime verification.
- Document exactly what was tested and what remains unverified.
