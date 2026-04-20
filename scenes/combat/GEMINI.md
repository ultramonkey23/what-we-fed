# COMBAT & TIMING — LOCAL INSTRUCTIONS

## Combat Soul
Combat in WHAT WE FED is about **timing honesty** and **lane integrity**. Every player action must feel responsive and every enemy presence must be readable.

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
- [ ] Is **no-pause during this level’s active song combat** preserved (no mid-fight menu/song freeze)?

## Anti-Drift: Combat
- **NO** auto-aim or auto-lane snapping that removes player agency.
- **NO** screen-filling particle explosions that hide the lanes.
- **NO** mid-level stop-start that breaks realtime lane combat; **between-level** reward/inventory flow is separate and intentional at run scope.
