# Potential System v1

## Purpose

Potential is a **layered ceiling stat**, not a flat combat-power stat.

In v1 it is used to cap encounter grade expression while preserving:
- RPG-first progression identity
- tendency as the live combat-growth layer
- species-specific DNA economy
- no-pause lane readability and timing truth

## v1 scope

Implemented in v1:
- creature-side Potential ceiling (authored in creature templates)
- world-side Potential ceiling (authored on route regions)
- one active consumer: encounter grade ceiling clamp in song-level phase build
- optional lair readout for collector-facing visibility (not combat HUD)

Explicitly not in v1:
- no direct player attack/defense scaling from Potential
- no tendency system rewrite
- no reward economy overhaul
- no metaprogression save integration

## Ownership model

### Creature Potential
- Source: `data/CombatContent.gd`
- Field: `potential_max_grade`
- Semantics: maximum encounter grade this active species can authorize

### World Potential Ceiling
- Source: `data/RouteContent.gd`
- Field: `potential_max_grade`
- Semantics: region threat ceiling for this run

### Run Potential Ceiling
- Source: `systems/PotentialGate.gd`
- v1 behavior: neutral (`alpha`) placeholder to keep ownership explicit without broad redesign

### Resolver + Clamp
- Resolver: `systems/PotentialGate.gd`
- Runtime injection: `scenes/combat/CombatScene.gd`
- Runtime consumer: `systems/EncounterIdentityRuntime.gd`

Resolution rule:
- `effective_ceiling = min(creature_ceiling, world_ceiling, run_ceiling)`
- encounter grade is clamped downward only

## Data contract

Allowed grade IDs (ordered low to high):
- `brood`
- `mature`
- `alpha`

New/used keys:
- `CombatContent.CREATURES[*].potential_max_grade: String` (optional; default `alpha`)
- `RouteContent.REGIONS[*].potential_max_grade: String` (optional; default `alpha`)
- `encounter_options.grade_ceiling_id: String` (runtime only; default `alpha`)

If a value is missing or invalid, `PotentialGate.normalize_grade_id()` resolves it to `alpha`.

## Runtime flow

1. `CombatScene` prepares level `encounter_options`
2. `CombatScene` resolves `grade_ceiling_id` through `PotentialGate.resolve_grade_ceiling(...)`
3. `CombatScene` passes `encounter_options` into `EncounterIdentityRuntime.build_song_run(...)`
4. `EncounterIdentityRuntime._build_scaled_song_level_phases(...)` clamps each enemy `grade` against `grade_ceiling_id`
5. Later enemy assembly still uses `CombatContent.ENCOUNTER_GRADES` multipliers (hp/damage/dna) with the clamped grade

## Current tuning notes

Current authored examples:
- `ashclaw`: `alpha`
- `bond_remnant`: `mature`
- `siltgrip`: `brood`
- regions currently default to `alpha`

This keeps behavior mostly unchanged while proving the ceiling path.

## UI/readout policy

Potential should appear in collector/readout surfaces first:
- `scenes/ui/LairScene.gd` now shows `Bond X | Pot Y` on creature cards

Potential should not add combat HUD clutter in v1.

## Validation checklist

Required after Potential changes:
1. `smoke_project.bat`
2. `run_project.bat` spot-check:
   - default `alpha` ceilings preserve existing pacing feel
   - low-potential creature visibly constrains grade expression as expected
3. confirm no new combat HUD stat clutter

## Safe extension path (post-v1)

Stage order for future expansion:
1. tune run-side ceiling logic in `PotentialGate.resolve_run_grade_ceiling(...)`
2. extend world-side region ceilings with authored differentiation
3. add optional reward/support ceiling consumers only after encounter-grade behavior is stable
4. wire meta Potential only when save ownership is finalized (do not anchor to unused systems)

