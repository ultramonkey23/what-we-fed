# COMBAT & TIMING — LOCAL INSTRUCTIONS

## THE AUTHORITY HIERARCHY
All combat design must adhere to the project's authority hierarchy:
1. **User / Creator Intent**: Highest authority.
2. **Current Repo Truth (Layer 2)**: Active `SongConductor` signals, input buffering, and state transitions.
3. **Older Canon / Source Docs (Layer 1)**: Timing honesty, lane integrity, and 1:1 input response. Useful memory and guidance; now considered secondary to Action-RPG beat-feel.

## Combat Soul: Combat-Clean
Combat in WHAT WE FED is about **beat-feel** and **directional threat clarity**. Every player action must feel responsive and every enemy presence must be readable.

- **Combat HUD = Urgency**: The live HUD must be stripped to the absolute essentials. If it doesn't help the player survive the next 200ms, it doesn't belong on screen during combat.
- **No Menu Sludge**: Never interrupt the active song flow with management popups or pause-heavy choice menus **during active in-level combat**.
- **Management Screens = Comprehension**: Push loot review, artifact choice, and detailed build decisions to the between-level or pre-run state where high-information density is encouraged.
- **Combat-Clean, Management-Rich**: The game is fast and pressure-first during levels, but thoughtful and strategic between them.

## Combat Field Rules
- **Action-RPG Hunting**: Combat is a freer field; enemies and projectiles focus on threat direction rather than rigid lanes.
- **Visual Priority**: Directional threat indicators and incoming threats must never be obscured by "cool" VFX.
- **Spawn Logic**: `CombatScene.gd` or dedicated threat managers own the cadence of arrival.

## Timing Truth & Beat-Feel
- **Master Clock**: `SongConductor.gd` is the source of truth for beats and timing.
- **Beat-Feel**: Player attacks and enemy attacks must feel on beat, but player agency remains active and responsive (movement, dodge, parry).
- **Feedback**: Visual/Audio feedback must occur at the exact moment of resolution and snap to the nearest beat when appropriate for impact feel.

## Implementation Rules
- **Player Actions**: Modify `PlayerCombat.gd` for input handling, damage calculation, and state (Attack/Parry/Dodge/Positioning).
- **Enemy Behavior**: Modify specific creature scripts for encounter logic and directional pressure.
- **Feedback Layer**: Use `systems/CombatImpactFeedback.gd` for impact effects. Keep it lean and ensure combat truth is never hidden.
- **UI/HUD**: `systems/CombatPresentationRuntime.gd` owns the live HUD. Clarity is king.

## Validation Checklist (Combat-Specific)
- [ ] Does the player still have active combat control (Movement/Timing)?
- [ ] Are directional threats clearly distinguishable (N/S/E/W)?
- [ ] Does the `SongConductor` beat signal remain accurate and felt?
- [ ] Did you test with `debug_harness.bat`?
- [ ] Is **combat-clean active song combat** preserved (no menu sludge/repeated interruption)?

## Anti-Drift: Combat
- **NO** screen-filling particle explosions that hide the threat directions.
- **NO** mid-song stop-start that breaks realtime combat flow.
- **Combat HUD = urgency** (minimalist). **Management screens = comprehension** (deferred to between-level state).
