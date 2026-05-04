# SOVEREIGN DIAGNOSTIC PROTOCOL (v1.0)

## Overview
The **Diagnostic Hub** (`DevHarness.gd`) provides real-time monitoring of the Sovereign Matrix. It is the primary tool for detecting "Soul Fractures" (logic desyncs) and "Pulse Decay" (timing inaccuracy).

## Key Metrics

### 1. Pulse Alignment (Beat Precision)
- **Signal**: `song_beat_pulse`
- **Goal**: Maintain average intensity > 0.8 during combat.
- **Fail State**: "Pulse Decay" — Indicates the song conductor or input processing is lagging.

### 2. Signal Integrity (Fracture Tracking)
- **Signal**: `_record_fracture(type, data)`
- **Common Fractures**:
    - `INPUT_REJECTION`: Player input denied despite valid timing.
    - `STALE_TRUTH`: Internal state mismatch between `GameState` and `CombatScene`.
    - `GHOST_RUN`: Active run processing with 0 HP player.

## Usage for AI Agents

When performing an audit, call `DevHarness.get_diagnostic_report()` to receive a JSON snapshot of the repo's health.

```gdscript
var report = DevHarness.get_diagnostic_report()
if report.state_consistency != "STABLE":
    # ESCALATE: Matrix fracture detected.
```

## Validation Ladder Integration
- **Level 3 (Runtime)**: Requires a "STABLE" consistency report from the Diagnostic Hub.
- **Level 4 (Playtest)**: Requires < 5 fractures over a 100-beat sequence.
