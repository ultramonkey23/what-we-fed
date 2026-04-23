---
name: wwf-combat-surgeon
description: Specialized combat and timing auditor for What We Fed. Use when editing combat logic, timing systems, or the HUD to ensure Timing Truth and Combat-Clean HUD rules.
---

# WWF Combat Surgeon

This skill provides expert guidance for maintaining the "Combat-Clean" and "Timing Truth" mandates of **What We Fed**.

## Core Mandates

1.  **Timing Truth**: `SongConductor.gd` is the absolute source of truth. All combat visual/audio resolutions must occur at the exact beat moment.
2.  **1:1 Input Response**: No "mushy" parries, dodges, or attacks. Input must be processed immediately.
3.  **Lane Integrity**: Threats and player actions must strictly occupy Lanes 0, 1, or 2. Do not bypass `LaneManager.gd`.
4.  **Combat-Clean HUD**: The HUD during active combat is for **urgency**, not information. Strip all "VFX Sludge" that doesn't help the player survive the next 200ms.

## Workflow

### 1. Timing Audit
When modifying `SongConductor.gd` or beat-triggered logic:
- Verify that `beat_progress` and `current_pulse` are the drivers for movement and telegraphing.
- Check the "Coyote Beat" (buffer window) for fairness.

### 2. HUD Surgery
When editing `CombatPresentationRuntime.gd` or HUD nodes:
- Audit for "VFX Sludge": Ensure lane indicators and incoming threats are never obscured by particles.
- Maintain lane-centric UI: Keep health, combo, and stamina near the focus area.

### 3. Feel & Feedback
When adjusting `CombatFeelConstants.gd` or `CombatImpactFeedback.gd`:
- Ensure hitstop (puncture) and slow-motion (stretch) are rare and earned.
- Align visual impacts perfectly with the audio transient.

## Reference Material

- **Timing Windows**: See [references/TIMING_WINDOWS.md](references/TIMING_WINDOWS.md)
- **VFX Priority**: See [references/VFX_PRIORITY.md](references/VFX_PRIORITY.md)
