# Metrist Downbeat / Ghost Pulse: alternative third species LIVE (pale_shelf_offbeat_lector)

LAB_RECEIPT_CONTRACT_V1:
RESULT: PASS
PROJECT_ID: what-we-fed
MISSION: Implement the Metrist — species id pale_shelf_offbeat_lector — LIVE and tryable per docs/ai/evolution_proposals/2026-11-23_metrist_alternative_third_species.md (the filed alternative design): jitter trigger (rhythmic regularity), TIMING DISPLACEMENT response (Downbeat one offbeat past the player's pulse; slip ONTO the pulse slot on pattern break), Ghost Pulse telegraph (echo fires in the gap, one beat early), [metrist_downbeat] causal marker on armed locked strikes, real spawn presence in pale_shelf encounters, own probe suite, windowed GPU proof.
ROUTING_DECISION: Lab game-brief trajectory PROCEED (MARGINAL_STABILITY, success=0.6452, net=14.34) honored — extended the established species-framework approach (Glintstalker/Shardhulk pattern) rather than restarting it. Mid-mission creator decision: the competing Cadenceleech was CANCELLED ("not both designs just the better one"); the Metrist is the single chosen third species.
FILES_CHANGED: systems/MetristDirector.gd (+.uid, new); scenes/combat/GhostPulseEcho.gd (+.uid, new); tools/test_metrist_ghost_pulse.gd (+.uid, new); scenes/combat/EnemyStriker.gd; scenes/combat/ZoneManager.gd; scenes/combat/Projectile.gd; scenes/combat/CombatScene.gd; systems/CreatureLocomotionDirector.gd; data/CombatContent.gd; data/RegionSongContent.gd; data/EnemyTemplates.gd; _visual_proofs/metrist_ghost_pulse/ (runtime_traces.txt, windowed_runtime_traces.txt, metrist_ghost_pulse_windowed_20261123.png); receipts/receipt_20261123_metrist_ghost_pulse.md
START_HEAD: 6552d1cf20217ab3f54985f6265606b21114d126 (mission start; later superseded by 9f3825e/bd93a29 from other workers)
END_HEAD: 6958d5d21f67f3ff420ecafbc59b0f505be5b024
COMMIT: 6958d5d21f67f3ff420ecafbc59b0f505be5b024 (feature commit; this receipt pin rides in the follow-up)
VALIDATION_RESULT: PASS
RECOMMENDED_NEXT_ACTION: Play one Pale Shelf encounter and teach the Metrist your groove — settle for a few pulses and read the Ghost Pulse echo, then break your cadence and watch the Downbeat slip onto your pulse slot; tune LOCK_JITTER_MAX / the slot geometry from the play report.

## FOR THE CREATOR — the two designs, and what you got

Two Lab creative runs invented third-species designs for the same space (comparison table: docs/ai/evolution_proposals/2026-11-23_metrist_alternative_third_species.md). You chose the Metrist ("just the better one"); the Cadenceleech is declined/superseded. What is live now, in the design's own terms:

- **Trigger — settling, not silence or panic.** The Metrist watches the jitter of your last inter-pulse intervals (`systems/MetristDirector.gd`). A comfortable groove (normalized MAD ≤ 12%, any tempo, ≥ 4 intervals) locks on; one rubato pulse breaks it. Silence and bursts are irrelevant as triggers — the triad reads: Glintstalker punishes HOLDING, Shardhulk punishes HAMMERING, Metrist punishes SETTLING.
- **Response — phase, never pace.** When locked, its signature strike **the Downbeat** is displaced into the empty slot one offbeat PAST your next pulse — the rhythm's own "safe" gap — by a pure launch-phase hold (`Projectile.set_timing_displacement`); projectile damage, projectile speed, orbit speed, timing windows and lane geometry are untouched (SovereignDamageCalculator stays damage authority). One Downbeat per lock.
- **Counterplay — deliberate rubato.** Break your pattern while the strike is in flight and it slips back ONTO the nearest player pulse slot it can physically reach — the readable trade/parry window. (Which pulse slot it lands on depends on when you break: an early break pulls it back onto the trailing pulse; a late break anchors it to your next one. The strike never moves faster than its fixed flight.)
- **Telegraph — the Ghost Pulse.** One beat before the Downbeat lands, a pale after-image of your OWN most recent shot ignites in the gap between two beats (`scenes/combat/GhostPulseEcho.gd`, headed by your last `player_attacked` heading). The readable rule holds as a hard invariant: **the echo fires in the gap, not on the beat** — even after a slip it snaps back into a gap slot.
- **Flavor-canon text is [P]-labelled** (display_name "[P] Metrist", description, signal_flavor, encounter summary) — name and line are revisable on your steer; the mechanic is real. The battlefield sprite is a placeholder reuse (precision-stalker art with a violet-white tint) pending real art.

## Technical Receipt

- Initial causal evidence: `data/CombatContent.gd` canon for pale_shelf_offbeat_lector described beat-keeping behavior no code implemented (design doc only). `EnemyStriker` remains the established HOW boundary; `ZoneManager._fire_striker` the single projectile spawn path.
- `systems/MetristDirector.gd` (new, typed GDScript): the rhythm engine — rolling 6-interval window, jitter = normalized mean absolute deviation, lock lifecycle (fresh lock arms exactly one Downbeat; rubato unlocks), pure deterministic slot math (pulse grid anchored on the last real pulse at the mean interval): `plan_downbeat` places the landing at pulse_slot + ½·interval with ghost ignition at landing − 1·interval (a gap slot exactly one beat early); `slip_plan` re-anchors onto the nearest reachable pulse slot at-or-after (now + remaining flight) and snaps the ghost to the gap before it. All plan keys are StringName per the Typed Instruction Mandate; the engine reads no autoloads.
- `scenes/combat/EnemyStriker.gd`: shared cadence clock forwards each pulse (with shot heading) to the Metrist engine; `METRIST_SPECIES`, `is_metrist` / `metrist_downbeat_armed` / `consume_metrist_downbeat` (consume only at guaranteed spawn), and `build_telegraph_profile(..., metrist_active)` sets `metrist_downbeat` + raised warning_bias. `compute_projectile_damage` / `compute_projectile_speed` deliberately gained NO Metrist parameters — timing only.
- `scenes/combat/Projectile.gd`: timing displacement = a phase hold at the current position (`set_timing_displacement` / `timing_displacement_remaining`; held seconds are excluded from the song-sync progress clock so the flight window shifts without any speed change). Inert unless applied — every other species' shots are byte-identical in behavior; eta queries include the hold so scheduling honesty is preserved.
- `scenes/combat/ZoneManager.gd`: consumes the Downbeat at the same guarantee point as the Glint/Close consumption; on armed locked strikes applies the displacement, registers the plan, spawns the Ghost Pulse echo, prints the causal marker `[metrist_downbeat] enemy=%d species=%s jitter=%.3f slot=offbeat hold=%.2fs landing_msec=%.1f ghost_msec=%.1f`, and emits readability cues ("THE DOWNBEAT" banner + pale screen flash) through the existing CombatScene consumers. `EventBus.player_attacked` now forwards the shot heading to the Ghost Pulse source.
- `scenes/combat/CombatScene.gd` (harness-only): `METRIST_DOWNBEAT` witness (seeds a live Metrist, teaches a 0.35s groove through the real EventBus wiring, fires through the production path, asserts flag + hold + lock) and `METRIST_SLIP` witness (fresh lock, second Downbeat, one rubato pulse 50ms in → strike slips onto the pulse slot). Both print `CONTROL_FOCUS_SEQUENCE` verdicts.
- `tools/test_metrist_ghost_pulse.gd` (113 checks, 0 failures) runs the production fire path headless: lock/unlock lifecycle (steady groove locks at jitter 0.000–0.04; rubato breaks); one-Downbeat-per-lock with re-arm only on a fresh lock; ghost-pulse snap timing (ignition == landing − mean interval, always a gap slot, echoed by the live node's scheduled time; snap preserved after a slip); irregular seeded input never locks; deterministic seeded runs reproduce identical lock outcomes, jitter and plans; slip math lands on-grid, reachable, hold == landing − earliest; the armed locked strike carries the Downbeat flag with damage 10.0 and speed 330.0 UNCHANGED (timing only); follow-up and unlocked shots are ordinary; in-flight pattern break slips the real projectile (hold 0.29→0.23s witness case) onto the pulse grid; Glintstalker/Shardhulk never fire Downbeats and the Metrist fires neither Glint Shots nor Lane Closes even under their triggers on the shared clock; spatial purity (lane, spawn and hit-zone geometry identical to the ordinary fire path); species + canon + locomotion authored in live data; spawn-weight wiring live (below).
- Spawn-weight evidence (real natural data path, `data/RegionSongContent.gd` SONG_PHASES_BY_REGION): the Metrist is fielded in **5/5 pale_shelf phase pools** (weights 0.22 opening / 0.24 rising / 0.24 chorus / 0.22 breakdown / 0.22 final — 1.14 of 6.86 total authored weight, **16.62% of all pale_shelf spawns**), alongside the Glintstalker and Shardhulk so the creator can compare both new species in one region. Seeded Monte Carlo (2000 rolls, seed 20261123, through `EncounterIdentityRuntime.pick_weighted_enemy` — the pure weighted owner behind production `_roll_weighted_entry`) measured **18.25% vs 18.03% authored** in the opening pool (`SPAWN_WEIGHT_FACT` / `SPAWN_MONTE_CARLO` lines in `_visual_proofs/metrist_ghost_pulse/runtime_traces.txt`). `data/EnemyTemplates.gd` demo-stack pools and `CreatureLocomotionDirector.LOCOM_PROFILES` (distinct metronomic tuple 1.00/0.88/0.05/false) carry the species too.
- Runtime witnesses (Godot 4.6.1):
  - Headless harness `debug_harness.bat --debug-control-sequence --debug-autoquit-seconds 90`: N/E/S/W steps PASS, `GLINT_PUNISH PASS` and `SHARD_PANIC_CLOSE PASS` (both pre-existing species re-verified with the independent test-author's new mutation controls), `CONTROL_FOCUS_SEQUENCE METRIST_DOWNBEAT PASS downbeat_flag=true locked=true hold=0.29s`, `METRIST_SLIP PASS slipped=true locked=false hold_before=0.29s hold_after=0.23s slot=pulse`, with the `[metrist_downbeat]` marker and `GHOST_PULSE_IGNITE scheduled_ignite_msec=... gap_slot=true` lines in the log.
  - **WINDOWED GPU run** (DebugBootScene WITHOUT --headless, Godot exe directly, env WHAT_WE_FED_DEBUG_PRESET=control_focus / AUTOLAUNCH=1 / AUTOQUIT_SECONDS=120): exit 0 on NVIDIA GeForce RTX 4080 Laptop GPU (OpenGL 3.3 Compatibility), all sequence steps PASS, both `[metrist_downbeat]` markers and both Ghost Pulse ignitions in `_visual_proofs/metrist_ghost_pulse/windowed_runtime_traces.txt`, and a live screenshot captured mid-ignition: `_visual_proofs/metrist_ghost_pulse/metrist_ghost_pulse_windowed_20261123.png` (verified by inspection: combat rendering live, the pale blue-white Ghost Pulse after-image visible beside the vessel).
- Collision notes: the mission's shared-file ban was LIFTED mid-mission by creator decision (Cadenceleech cancelled); the Metrist was integrated into EnemyStriker/ZoneManager/CombatScene in the established species-framework pattern (shared player-cadence clock). The cancelled Cadenceleech worker left **no code partials** (verified: no cadenceleech/cadence_leech/cadence_lock references anywhere in source; clean `git status` of tracked files). Its proposal doc was committed by another worker (9f3825e) already marked DECLINED/superseded; nothing was built on it.
- Housekeeping: prior gen-1/gen-2 suites were re-run after the integration — `test_glint_stalker_silence_punish` 43/0, `test_shardhulk_panic_close` 56/0 (including bd93a29's independent third-shot-purity mutation controls), `test_glint_natural_spawn_presence` 101/0, `test_enemy_pressure_spread` 22/0, plus the other eight probes all TEST OK.

## WHAT WE FED Agent Report

Agent: Hermes (Nous Research) — subagent executor
Date: 2026-11-23
Branch/commit if available: master / pending-commit
Task type: Feature (third species, live + tryable)

Files inspected: proposal docs (Metrist + Cadenceleech comparison), `AGENTS.md`, `docs/ai/SOVEREIGN_CORE.md`, `docs/ai/CURRENT_PULSE.md`, `scenes/combat/{EnemyStriker,ZoneManager,CombatScene,Projectile,ThreatBase}.gd`, `data/{CombatContent,RegionSongContent,EnemyTemplates}.gd`, `systems/{CreatureLocomotionDirector,EncounterEscalationDirector,EncounterIdentityRuntime,SectorLayout}.gd`, `tools/test_{glint_stalker_silence_punish,shardhulk_panic_close,glint_natural_spawn_presence,enemy_pressure_spread}.gd`, `tools/validate_data_content.gd`, `tools/godot.ps1`, `scenes/dev/DebugBootScene.gd`

Files changed:
- `systems/MetristDirector.gd` (+.uid) — new rhythm engine
- `scenes/combat/GhostPulseEcho.gd` (+.uid) — new Ghost Pulse telegraph visual
- `tools/test_metrist_ghost_pulse.gd` (+.uid) — new probe suite (113 checks)
- `scenes/combat/EnemyStriker.gd`, `scenes/combat/ZoneManager.gd`, `scenes/combat/Projectile.gd`, `scenes/combat/CombatScene.gd` — species-framework integration + harness witnesses + phase-hold support
- `systems/CreatureLocomotionDirector.gd`, `data/CombatContent.gd`, `data/RegionSongContent.gd`, `data/EnemyTemplates.gd` — live data entries + spawn weights
- `_visual_proofs/metrist_ghost_pulse/` — headless traces, windowed traces, windowed screenshot
- `receipts/receipt_20261123_metrist_ghost_pulse.md`

Validation run: `validate_project.bat` (VALIDATE OK + SUCCESS: Data content is valid); `validate_data.bat` (DATA VALIDATION OK); all thirteen `tools/test_*.gd` probes via `tools/godot.ps1 test` — new `test_metrist_ghost_pulse` 113 checks / 0 failures, all twelve pre-existing TEST OK; headless debug-harness control sequence all PASS; one windowed GPU run (120s autoquit, exit 0, all PASS).

Validation level: 3
Validation result: PASS — deterministic probe coverage of the full behavior contract plus headless AND windowed-GPU CombatScene runs whose logs carry the causal markers only the change could produce, with a captured visual frame of the Ghost Pulse.

Confirmed repo truth:
- `EventBus.player_attacked` → `ZoneManager._on_player_attacked_pulse` → `EnemyStriker.note_player_attack` is the shared cadence clock all three species read; the Metrist engine hangs off the same hook.
- `ZoneManager._fire_striker` is the single projectile spawn path; telegraph flags ride `Projectile.tscn` untouched; `RegionSongContent` weights are the base of production natural spawns.

Unverified assumptions / unknowns:
- **Play-feel is UNKNOWN until Cody plays**: whether the lock threshold (LOCK_JITTER_MAX=0.12 normalized MAD over 6 intervals) feels like "comfort" rather than noise, whether the offbeat landing reads as unfair or delicious, and whether the Ghost Pulse is legible at game speed. All constants live in `systems/MetristDirector.gd` + `scenes/combat/ZoneManager.gd` (GHOST_PULSE_*) and are safe to tune live.
- **Independent test authorship UNVERIFIED for `tools/test_metrist_ghost_pulse.gd`**: the Lab's standing independent test-author subagent could not be reached from this session, so the probe was authored by the implementation executor. (The independent body did land mutation controls for the glint/shard suites in bd93a29, which this run re-verified green; the Metrist probe itself awaits independent review.) The probe expectations are self-authored until then.
- [P] flavor text (name "Metrist", the two lines) is provisional by direction; the battlefield sprite is a placeholder reuse (precision-stalker png + violet tint) until real art exists.
- DNA reward for the Metrist is wired to `veilskin` (the pale_shelf precision DNA) as a gen-1 placeholder — the proposal defines no DNA identity; revisable on steer.
- The slip's landing direction (earlier vs later slot) depends on when the pattern breaks relative to the fixed flight — physically honest ("never speed scaling") but its readability in motion is untested.
- The measured spawn share is the authored unmodulated base; live grade/pressure multipliers shift it in a real run (same caveat as the gen-1 measurement).
- Godot reports `ObjectDB instances leaked at exit` on harness/test shutdown — pre-existing accepted wrapper warning, root cause not investigated.

Risks:
- The rhythm engine's statics are shared per combat like the other species' clock state; if a fourth cadence identity appears, extract the clock to its own owner (the gen-2 receipt's standing recommendation).
- If the lock threshold proves too strict for human play, the Metrist becomes invisible; if too loose, it punishes noise. The probe suite pins the CURRENT contract — retune the probe expectations together with the constants.

## Auditor's Report (v2.5)

- **Task Type**: Feature (third reactive species, live + tryable)
- **Blast Radius**: Tier 2 (combat fire path + data; all changes species-gated)
- **Evidence Type**: Runtime-Verified (headless + windowed GPU + captured visual frame)
- **Visual Proof**: `_visual_proofs/metrist_ghost_pulse/metrist_ghost_pulse_windowed_20261123.png` — live windowed combat frame with the pale Ghost Pulse after-image visible beside the vessel (verified by image inspection), plus headless + windowed runtime traces carrying `[metrist_downbeat]` and `GHOST_PULSE_IGNITE` markers.
- **Self-Critique Results**:
  - [x] Assumption-Busted (spawn-weight UNKNOWN resolved by measurement over the real data path + seeded Monte Carlo)
  - [x] Identity Anchor Integrity (Timing/DNA/Beat-Feel — trigger and response are pure timing; damage/speed/lane untouched, asserted)
  - [x] Anti-Sludge (Combat-Clean — cues reuse existing banner/flash channels; no new HUD)
  - [x] GDScript 2.0 Compliance (static typing, typed arrays, StringName keys/labels)
  - [x] Signal Tracing (player_attacked consumed AND asserted through the real wiring)
  - [x] Null-Safety (weakref guards, sentinel conventions honored)
  - [x] Visual Proof Rule (windowed screenshot + logs)
- **Verified Facts**: locked groove → armed Downbeat displaced one offbeat past the pulse via phase hold with damage 10.0/speed 330.0 unchanged; Ghost Pulse ignites in a gap exactly one beat early (snaps to a gap after slips); one Downbeat per lock with re-arm on fresh lock; irregular input never locks; seeded determinism; pattern break slips the strike onto a reachable pulse slot; species identity isolation in both directions; spatial purity; live spawn in 5/5 pale_shelf pools; 113/0 new probe, twelve pre-existing probes green, validators green, both runtime witnesses green.
- **Unverified Risks**: play-feel, telegraph readability at game speed, independent authorship of the new probe, DNA/sprite placeholders.
- **Next Bounded Move**: one human Pale Shelf play observation ("settle, then rubato") to tune LOCK_JITTER_MAX and the Ghost Pulse visibility window from real feel.

## Self-Upgrade Check

- **Repo Truth Changed**: yes — the Metrist is live combat behavior with real spawn presence; the alternative-species competition is resolved (Metrist selected, Cadenceleech declined).
- **Player Understanding Changed**: pending human play — the Pale Shelf triad (holding/hammering/settling) is now mechanically complete and tryable.
- **Current Pulse Update Needed**: optional — "Enemy variety needs more readable species identity" now has a third concrete answer; leave wording to its owner.
- **Agent Rule Update Needed**: no.
- **New Eval Case Needed**: no — `tools/test_metrist_ghost_pulse.gd` is the standing regression probe.
- **Soul / Taste Lesson Learned**: yes — the same input (player cadence) yields a third identity when the answer is WHERE a strike lands instead of how fast: phase is a weapon dimension distinct from pace.
- **Recommended Doctrine Patch**: none.
- **One-Sentence Learning**: A rhythm enemy becomes real when its telegraph teaches the rule before the strike enforces it — the echo in the gap is the lesson, the Downbeat is the exam.
