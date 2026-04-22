# WWF Timing Windows Reference

## Core Timing Logic
The `SongConductor` determines the heartbeat of combat.

- **The "Perfect" Hit**: Handled by the `100ms` window around the beat transient.
- **Coyote Beat**: A ~50ms pre-beat and ~50ms post-beat buffer that allows inputs to "snap" to the beat.
- **Visual-Audio Sync**: VFX must trigger at `Frame 0` of the beat resolution.

## Beat Quality Mapping
- **Perfect**: 0.0 - 0.1 beat phase.
- **Great**: 0.1 - 0.2 beat phase.
- **Early/Late**: Outside the 0.2 phase window.

## Feel Constants
- **Hitstop (Puncture)**: 0.05s to 0.1s.
- **Slow-Mo (Stretch)**: 0.4x speed for 1-2 seconds max.
- **Void (Choice)**: 0.0x speed during live reward choice.
