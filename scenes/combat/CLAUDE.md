# CLAUDE.md - Combat

Combat is the highest-risk hot path. Timing truth, lane readability, action response clarity, support readability, and combat honesty outrank visual flourish and abstraction.

- Start with `CombatScene.gd`, then inspect `PlayerCombat.gd`, `LaneManager.gd`, `systems/CombatMeter.gd`, `systems/SongConductor.gd`, and relevant `data/` owners as needed.
- Do not reintroduce pause-era reward/growth as the main combat spine.
- Keep player inputs responsive; do not mask misses, hits, parries, dodges, or support effects.
- When touching `CombatScene.gd`, isolate the change and name the exact runtime contract being protected.
- Validate at least with `smoke_project.bat`; use `debug_harness.bat` or `run_project.bat` when timing/readability/feel is the claim.
