# WORKFLOW: SNAPSHOT GENERATOR (v1.0 "The Pulse Check")

## Purpose
The Snapshot Generator is a **SYMBIOTE (Scout)** protocol designed to maintain a high-signal, compact "State Vector" of the repository. It prevents context degradation and "prompt bloat" by providing agents with an instant, fresh summary of the live repo truth.

## 1. THE CURRENT PULSE
The generator writes `docs/ai/archive_legacy/truth_history/CURRENT_TRUTH_SNAPSHOT.md` (archived path; optional machine refresh). Default agent **Working Memory** for human-curated pulse is `docs/ai/CURRENT_PULSE.md`.

## 2. GENERATION TRIGGER
The snapshot should be refreshed:
- At the start of a new major task.
- After a successful `smoke_project.bat` or `validate_data.bat` run.
- Whenever Layer 2 Truth (implementation) has mutated significantly.

## 3. SNAPSHOT CONTENT (High-Signal Only)
A valid snapshot must contain:
- **Git Pulse**: Recent commits and modified files (Last 3-5 changes).
- **Validation Pulse**: Last status of `smoke_project.bat` and `validate_data.bat`.
- **Active Bottlenecks**: Known blockers or high-priority triage tasks.
- **Pulse Highlights**: Key updates from `docs/ai/PULSE_REPORT_V1.md`.
- **Identity Integrity**: Confirmation that identity anchors (Timing, Lanes, DNA) are intact.

## 4. TOOL INTEGRATION
Use `tools/generate_snapshot.bat` to automate the collection of these signals. The script hashes the current state to ensure the snapshot is deterministic and fresh.

## Protocol for Agents
1. **SYMBIOTE** runs the generator to refresh the pulse.
2. **BRAIN** reads the snapshot first to ground the "Best-Next-Move."
3. **ALFRED** uses the snapshot to ensure mutations don't collide with recent changes.

## Output Contract
The Snapshot Generator output is static documentation; it does not require an Auditor's Report, but its *creation* or *significant update* should be noted by SYMBIOTE.
