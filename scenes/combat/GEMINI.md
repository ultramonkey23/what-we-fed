# COMBAT & TIMING — LOCAL INSTRUCTIONS

## THE AUTHORITY HIERARCHY
All combat design must adhere to the project's authority hierarchy:
1. **User / Creator Intent**: Highest authority.
2. **Current Repo Truth (Layer 2)**: 360-degree spatial interaction, ID-authoritative resolution.
3. **Older Canon / Source Docs (Layer 1)**: Rigid lane-snapping and grid-based interaction. **RETIRED**.

## Combat Soul: Spatial Action-RPG
Combat in WHAT WE FED is a freer hunting field. The **Living Codex** (player) interacts with physical entities in 3D space, not UI slots.

- **Spatial Purity**: No mechanical interaction may rely on lane indices. Attacks, Parries, and Supports sweep the world spatially.
- **Lanes = Spawn Anchors**: Lane integers (0-7) are strictly for visual routing (HUD rings) and designating where an entity *arrives* on the battlefield.
- **Manga Impact Framing**: Every successful "Perfect" action must freeze the world (Hit-Stop) and shake the camera (Splash-Page weight).
- **Honest Range**: Mechanical reach must match visual asset size (e.g. Energy Sword = 220.0 units).

## Timing Truth & Beat-Feel
- **Master Clock**: `SongConductor.gd` remains the heartbeat.
- **Juice**: `CombatFeedbackDirector` orchestrates all hyperbolic feedback.
- **Urgency**: HUD rings map spawn-sector pressure.

## Implementation Rules
- **Player Actions**: `PlayerCombat.gd` handles spatial 360 aim and AoE resolution.
- **Enemy Behavior**: ID-authoritative damage and status.
- **Decoupling**: Never fallback to lane-damage if a spatial swing misses. Whiffs are honest.

## Validation Checklist (Combat-Specific)
- [ ] Is interaction 100% ID or Spatial (No `damage_enemy(lane)`)?
- [ ] Does the Energy Sword's visual reach match the targeting `max_range`?
- [ ] Does "Perfect" impact trigger the `CombatFeedbackDirector`?
- [ ] Is the 360-degree facing stable (no flipping sprite mirroring)?
- [ ] Did you test with `debug_harness.bat`?

## Anti-Drift: Combat
- **NO** returning to lane-snapping interaction.
- **NO** "magical" damage to empty lanes.
- **NO** desyncing visual reach from mechanical range.
