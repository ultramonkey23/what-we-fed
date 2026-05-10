# Timing Ring / Hitbox / Slowmo Pass Notes

- Static contract: `CombatFeelContent.RING_OUTER_RADIUS` and `RING_PERFECT_RADIUS` now drive both timing resolution and central sigil presentation scale.
- Hitbox contract: projectile player contact radius was tightened, while attack/parry proximity grace is centralized and smaller than the previous hidden `+12` good radius.
- Tempo contract: player-hit hit-stop is shorter, and perfect parry no longer receives duplicate hit-stop from `CombatFeedbackDirector` on top of `PlayerCombat` quality-based slowmo.
- Dodge feel: baseline dodge recovery, push duration, shake, spin, and squash were reduced to preserve response clarity.
- Visual proof limitation: no manual gameplay screenshot was captured in this pass. Static validation and smoke logs are included under `logs/`.
