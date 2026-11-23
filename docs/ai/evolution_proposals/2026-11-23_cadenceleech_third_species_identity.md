# Proposal: Cadenceleech — third reactive species identity (pale_shelf_cadence_leech)

STATUS: DECLINED — superseded by 2026-11-23_metrist_alternative_third_species.md
on the creator's decision (2026-11-23: "not both designs just the better one";
the Metrist's counterplay depth and roster coherence won). This document is
retained as the design-comparison history, not as live canon or content. Any
partial Cadenceleech implementation is reverted, per the Supersession law
(delete the weaker live copy; history preserves provenance).

## Problem Observed
The Glintstalker (pale_shelf_precision_stalker, "It counts the silence between
your pulses") and Shardhulk (pale_shelf_shardshroud_sentinel, "A plated weight
that expects you to panic") establish a reactive-species framework keyed to the
PLAYER's attack cadence with opposite triggers and opposite speed responses
(silence -> faster/heavier; panic-burst -> slower/heavier). The species identity
demo gap (docs/ai/CURRENT_PULSE.md) benefits from a third identity occupying the
remaining design space of the framework — and the Lab's creative cognition organ
(Spark routed through Six Mind / Cyber Cody deliberation) produced an original
design that fits it.

## Evidence
- docs/ai/CURRENT_PULSE.md: "Enemy variety needs more readable species identity and pressure spread."
- Existing framework: EnemyStriker silence-punish + panic-close (receipts/receipt_20261123_glint_stalker_silence_punish.md, receipts/receipt_20261123_shardhulk_panic_close.md).
- Design origin: Lab Spark species-invention task, 2026-11-23 (Spark activation organ; creative invention, design-only, no code). Author: Lab creative cognition body (assistant-origin), NOT creator-authored canon.
- Repo canon laws cited in the design: docs/ai/SOVEREIGN_CORE.md (timing truth, spatial purity, sequential mutation, Visual Proof Rule, Legendary Pixel Fable Ink).

## Affected Files/Systems
- scenes/combat/EnemyStriker.gd (behavior layer, cadence clock owner)
- scenes/combat/ZoneManager.gd (fire path; unchanged spatial authority)
- species/locomotion data naming (pale_shelf_* convention; CombatContent.gd / RegionSongContent.gd provenance)
- tools/test_cadenceleech_ghost_beat.gd (new probe suite, [P] experiment)

## Proposed Change
Add the **Cadenceleech** — species id `pale_shelf_cadence_leech` — as the third
reactive species identity:

1. **Flavor canon line (PROPOSED, pending approval):** "It keeps the beat you
   forgot you were keeping." Visual: a pale, many-limbed metronome-thing;
   ink-cut silhouette; only its echo-crest carries a faint Bone Ink omen shimmer
   (Bone Ink remains the corruption layer only).
2. **Trigger — rhythm regularity (fluency, neither silence nor burst):** a
   rolling window of the last ~6 player pulse timestamps (READ-ONLY cadence
   observation riding the existing fire authority — CombatFireDirector owns
   fire dispatch; the species only listens). When inter-pulse intervals fall
   into a groove (low variance against the player's own median interval), the
   creature "learns your beat."
3. **Response axis — phase displacement (opposite of speed scaling):**
   - LOCKED (trigger met): the signature strike phase-locks one beat BEHIND the
     player's pulse, landing in the predicted recovery window ("downbeat thief").
   - UNMOORED (player varies cadence): the lock shatters; timing drifts a full
     beat wide — the telegraphed strike arrives late and mistimed.
   Damage math stays in SovereignDamageCalculator; this species sets TIMING
   only (timing truth: reactions to measured live pulse timestamps).
4. **One-warning telegraph — the Ghost Beat:** while learning, one pale ink
   flash exactly one beat AFTER each player pulse (an after-echo of the
   player's own rhythm). The single warning is the snap: when the flash slides
   ONTO the beat instead of after it, the lock is complete and the bite rides
   the next recovery window. One flash, one state change (Visual Proof Rule:
   capture under _visual_proofs/ when built).
5. **Encounter dynamic:** Glintstalker punishes hesitation, Shardhulk punishes
   panic — Cadenceleech punishes MASTERY (the optimal rotation is the groove it
   eats; survival demands deliberate irregularity). Anti-synergy pair with
   Glintstalker: no long gaps AND no perfect rhythm. Spatially pure: timing
   manipulation only; ZoneManager stays sole spatial owner; no LaneManager
   revival.

## Risk
- New flavor canon line and species identity are CREATIVE CANON — must not be
  presented as approved canon while this proposal is open (LAW 5 terminology
  and the repo's controlled-evolution gate apply).
- Cadence learning must never become a second shooter or a spatial system
  (spatial purity); it must read only the existing player-attack signal.
- "Play worse on purpose" tension could read as unfair if the Ghost Beat
  telegraph is not readable — readability proof required before any promotion.
- Determinism: rolling-window learning must be reproducible in probes.

## Validation Plan
- New probe suite tools/test_cadenceleech_ghost_beat.gd in the gen-1/2 pattern:
  learn/lock/unmoor lifecycle, one-punish-per-lock, telegraph snap timing,
  non-cadence inputs never lock, deterministic seeded behavior; causal marker
  [cadence_lock] exactly on armed locked strikes.
- validate_project.bat + validate_data; all pre-existing probes stay green.
- Debug-harness witness step (SHARD_PANIC_CLOSE-style) + windowed GPU run with
  the causal marker observed in the runtime log; screenshot under
  _visual_proofs/cadenceleech_ghost_beat/.
- Play-feel/readability remain UNKNOWN until Cody plays; the flavor line and
  species name remain PROPOSED until Command Center approval.

## Rollback Plan
Revert the species data entry and EnemyStriker cadence-learner block (the
behavior is self-contained behind its species id and shared cadence clock);
the probe suite and this proposal doc may remain as history. No other system
consumes the species id while unapproved (spawn weighting set to zero /
harness-only until approval).
