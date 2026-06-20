# WHAT WE FED — CREATURE ECONOMY IMPLEMENTATION MAP V1

## Read

- This file operationalizes `CREATURE_ECONOMY_DOCTRINE_V1.md`.
- Doctrine defines truth; this map defines implementation routing.
- If implementation conflicts with doctrine, doctrine wins.

## Purpose

- Give design, canon, and systems a single translation layer.
- Prevent lane blur during data schema, UI, and balancing work.
- Keep creature progression anti-drift during prototype growth.

## Lane Ownership Matrix

- `InitialBondUnlock` owns first-time species acquisition and permanent archive unlock.
- `PredationDebtBondResistance` owns pre-unlock species resistance pressure.
- `BondRank` owns milestone breakthroughs and meaningful evolution triggers.
- `CreatureLevel` owns practical incremental tuning and support efficiency.
- `CreaturePotential` owns long-horizon ceiling and lineage depth growth.
- `RepeatSpeciesRouting` owns post-unlock value routing into valid sinks.
- `PostMaxRareSpecimen` owns exceptional specimen chase after max Bond Rank.

## Canon Data Model (Draft Contract)

- `species_id`: stable species key across all lanes.
- `species_unlocked`: bool; set only by first successful bond.
- `first_bond_timestamp`: used for archive history and telemetry.
- `predation_debt`: pre-unlock resistance scalar; clamped.
- `bond_rank`: milestone index (not freeform xp level).
- `bond_rank_progress`: bounded milestone input meter.
- `creature_level`: practical growth counter.
- `creature_level_xp`: regular level input meter.
- `potential_tier`: meta depth tier.
- `potential_progress`: long-horizon potential input meter.
- `bond_rank_maxed`: bool unlock gate for rare specimen lane.
- `rare_hunt_unlocked`: bool; true when `bond_rank_maxed == true`.
- `specimen_quality_band`: uncommon/rare/exceptional outcome band.
- `variant_form_tag`: variant identity marker.
- `lineage_grade`: lineage expression band.
- `signal_purity`: rare expression scalar within specimen lane.

## Event Hooks (System Routing)

- `on_species_encountered(species_id)`
  - Routes to repeat species logic if unlocked.
  - Evaluates pre-unlock predation pressure if locked.
- `on_species_eaten(species_id)`
  - If locked: increase `predation_debt`.
  - If unlocked: feed valid sinks (`creature_level_xp`, `bond_rank_progress`, `potential_progress`) per design routing.
- `on_bond_attempt(species_id)`
  - If locked: apply `predation_debt` resistance curve.
  - If success and locked: set `species_unlocked = true`, clear/retire pre-unlock debt behavior.
- `on_bond_milestone_reached(species_id, milestone_id)`
  - Advance `bond_rank`.
  - Trigger meaningful evolution package and identity shifts.
  - Never triggered by `creature_level` alone.
- `on_level_up(species_id)`
  - Apply practical stat/efficiency tuning only.
  - No form evolution execution.
- `on_potential_tier_up(species_id)`
  - Expand eligible ceiling/branch set.
  - No direct evolution fire.
- `on_bond_rank_maxed(species_id)`
  - Set `rare_hunt_unlocked = true`.
  - Enable exceptional specimen encounter table.

## Reward Routing Contract

- Every encounter output must name one primary lane destination.
- Secondary routing is allowed only if primary lane is explicit.
- Valid post-unlock sinks:
  - immediate run power
  - creature level input
  - bond milestone input
  - potential input
  - species mastery/archive depth
  - rare hunt support
- Invalid routing:
  - fake rebond of already unlocked species
  - unlabeled reward output with no lane destination
  - leveling output that claims milestone evolution authority

## Evolution Trigger Contract

- Evolution trigger source: `BondRank milestone events` only.
- `CreatureLevel` cannot directly fire major evolution transitions.
- `CreaturePotential` can gate branch eligibility, never directly fire evolution.
- First unlock is an acquisition event, not a substitute evolution event.

## Predation Debt Safety Contract

- Applies only while `species_unlocked == false`.
- Increases bond resistance pressure with visible readability.
- Must be bounded by soft-cap ranges.
- Must not create normal-play hard locks.
- Retires as a blocker after first successful unlock.

## Rare Specimen Lane Contract

- Activation gate: `bond_rank_maxed == true`.
- Replaces infinite normal bond progression.
- Uses canon language:
  - `Specimen Quality`
  - `Variant Form`
  - `Lineage Grade`
  - `Signal Purity`
- If preservation storage is implemented later, it must be archive apparatus language (for example, `Sequence Stasis`), not capture-device mimicry.

## UI/UX Surface Rules

- Always show active lane context near progression updates.
- Bond milestone screens must read as identity events, not stat popups.
- Level-up screens must read as practical tuning updates.
- Potential screens must read as long-horizon depth expansion.
- Predation debt feedback must show clear cause/effect before first unlock.
- Repeat encounter rewards must show destination lane labels.

## Telemetry Requirements

- Track first unlock rates per species.
- Track pre-unlock predation debt distribution and bond success correlation.
- Track bond milestone completion pacing by species line.
- Track level progression pacing separately from bond milestones.
- Track potential progression pacing as long-horizon metric.
- Track post-max rare hunt engagement and exceptional specimen hit rates.

## Validation Checklist (Implementation Gate)

- Does the feature declare a single primary lane owner?
- Does each reward output name a destination sink?
- Does any level or potential hook directly trigger evolution? If yes, reject.
- Can first bond still happen under normal play despite predation debt? If no, reject.
- Are repeated species encounters always valuable after unlock? If no, reject.
- Does post-max design avoid infinite normal bond extension? If no, reject.
- Does terminology drift into collector-game mimic language? If yes, reject.

## Minimum Build Sequence

- Step 1: implement lane-tagged species state model.
- Step 2: implement pre-unlock predation debt routing and readable feedback.
- Step 3: implement first unlock permanence and archive persistence.
- Step 4: implement Bond Rank milestone triggers with evolution hooks.
- Step 5: implement Creature Level practical tuning lane.
- Step 6: implement Creature Potential ceiling lane.
- Step 7: implement repeat-species routing view and sink labeling.
- Step 8: implement post-max rare specimen lane gates and telemetry.

## Non-Goals

- This map does not set numeric balance values.
- This map does not define final UI art direction.
- This map does not redefine world-state consequence canon.
- This map does not alter combat timing systems.
