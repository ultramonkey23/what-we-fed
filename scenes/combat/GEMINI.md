# COMBAT & TIMING — LOCAL INSTRUCTIONS

## 5-Layer Canon Compliance
All combat logic must adhere to the **5-Layer Canon Model** defined in the Project Kernel:
1. **Layer 1 (Locked Core)**: Timing honesty, lane integrity, and 1:1 input response.
2. **Layer 2 (Live Build Truth)**: Active `SongConductor` signals override stale documentation.
3. **Layer 3 (Evolving Spine)**: Combat feel constants and VFX intensity.

## Combat Soul: Combat-Clean
Combat in WHAT WE FED is about **timing honesty** and **lane integrity**. Every player action must feel responsive and every enemy presence must be readable.

- **Combat HUD = Urgency**: The live HUD must be stripped to the absolute essentials. If it doesn't help the player survive the next 200ms, it doesn't belong on screen during combat.
- **No Menu Sludge**: Never interrupt the active song flow with management popups or pause-heavy choice menus **during active in-level combat**.
- **Management Screens = Comprehension**: Push loot review, artifact choice, and detailed build decisions to the between-level or pre-run state where high-information density is encouraged.
- **Combat-Clean, Management-Rich**: The game is fast and pressure-first during levels, but thoughtful and strategic between them.

## Lane Rules
- **Lane Locking**: Enemies and projectiles must strictly occupy lanes 0, 1, or 2.
- **Visual Priority**: Lane indicators and incoming threats must never be obscured by "cool" VFX.
- **Spawn Logic**: `LaneManager.gd` owns the rhythm of arrival. Do not bypass it.

## Timing Truth
- **Master Clock**: `SongConductor.gd` is the absolute source of truth for beats and timing.
- **Input Window**: Tight, honest windows. No "mushy" parries or dodges.
- **Feedback**: Visual/Audio feedback must occur at the exact moment of resolution.

## Implementation Rules
- **Player Actions**: Modify `PlayerCombat.gd` for input handling, damage calculation, and state (Attack/Parry/Dodge).
- **Enemy Behavior**: Modify `CombatScene.gd` or specific creature scripts for encounter logic.
- **Feedback Layer**: Use `systems/CombatImpactFeedback.gd` for impact effects. Keep it lean.
- **UI/HUD**: `systems/CombatPresentationRuntime.gd` owns the live HUD. Clarity is king.

## Validation Checklist (Combat-Specific)
- [ ] Does the player still have 1:1 input control?
- [ ] Are lanes 0, 1, and 2 still clearly distinguishable?
- [ ] Does the `SongConductor` beat signal remain accurate?
- [ ] Did you test with `debug_harness.bat`?
- [ ] Is **combat-clean active song combat** preserved (no menu sludge/repeated interruption)?

## Anti-Drift: Combat
- **NO** auto-aim or auto-lane snapping that removes player agency.
- **NO** screen-filling particle explosions that hide the lanes.
- **NO** mid-song stop-start that breaks realtime lane combat.
- **Combat HUD = urgency** (minimalist). **Management screens = comprehension** (deferred to between-level state).
