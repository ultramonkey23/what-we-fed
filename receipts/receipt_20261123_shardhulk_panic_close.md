# Shardhulk Panic Close: second reactive species identity + natural Glintstalker spawn measurement

LAB_RECEIPT_CONTRACT_V1:
RESULT: PASS
PROJECT_ID: what-we-fed
MISSION: Generational extension — give a SECOND species (Shardhulk, pale_shelf_shardshroud_sentinel) a distinct observable combat behavior derived from its own flavor canon (a different rule from the Glintstalker's silence-punish), wired into the real CombatScene with its own causal marker and probe suite in the gen-1 pattern; also resolve one gen-1 UNKNOWN by measuring how often natural (non-harness) encounters field Glintstalkers (spawn weights in data/).
ROUTING_DECISION: Lab game-brief trajectory PROCEED (MARGINAL_STABILITY, success=0.6786, net=13.6) honored — "extend the current approach rather than restarting it"; see Approach Difference.
FILES_CHANGED: scenes/combat/EnemyStriker.gd; scenes/combat/ZoneManager.gd; scenes/combat/CombatScene.gd; tools/test_shardhulk_panic_close.gd; tools/test_shardhulk_panic_close.gd.uid; tools/test_glint_natural_spawn_presence.gd; tools/test_glint_natural_spawn_presence.gd.uid; _visual_proofs/shardhulk_panic_close/; _visual_proofs/glint_stalker_silence_punish/rendered_live_run_20261123.png (+.import, gen-1 untracked proof integrated); receipts/receipt_20261123_shardhulk_panic_close.md
START_HEAD: 7f834758272713968cf0157e14f42de6ea2b2486
END_HEAD: pending-finish
COMMIT: pending-finish
VALIDATION_RESULT: PASS
RECOMMENDED_NEXT_ACTION: Play one Pale Shelf encounter to judge whether the plate-click telegraph reads at game speed, and tune SHARD_PANIC_GAP / SHARD_PANIC_BURST / close multipliers from the play report.

## Director Readable

The Shardhulk's canon says "A plated weight that expects you to panic. It closes the lane with the cold patience of a glacier" and "Its plates click once before it fires. The click is the only warning." That identity is now live combat behavior. Where the Glintstalker punishes SILENCE (a widened gap between player pulses → a faster shot), the Shardhulk punishes PANIC: a burst of rapid player pulses (3 attacks each within 1s of the last) is exactly the panic it expects, and its next spawned shot becomes a **Lane Close** — 1.5x damage and 0.72x projectile speed (a heavy glacial slab that closes the lane instead of chasing a timing window), telegraphed by a raised plate-click warning ("PLATES CLICK" proc banner + pale-green screen flash through the existing CombatScene consumers). Exactly one Lane Close fires per panic episode; a calm-spaced pulse disarms it and only a fresh burst re-arms it. The two species now form a readable cadence pair: keep a pulse vs keep your cool.

Measured fact resolving the gen-1 UNKNOWN (natural Glintstalker presence): in the authored natural spawn tables (`data/RegionSongContent.gd`), the Glintstalker is fielded in **4 of 15 phase pools — all in pale_shelf (4 of its 5 phases; absent only from "breakdown"), with 0 presence in feeding_hollow and drowned_cut**. Inside those pools its weight share is 21.7–28.0% of natural spawns (opening 28.00%, rising 27.12%, chorus 21.67%, final 22.41%; 6.73% of total authored weight across all pools). A seeded Monte Carlo through the codebase's weighted picker reproduced every share within 1.1pp. So roughly a quarter of natural spawns in most Pale Shelf phases are Glintstalkers — frequent enough for players to learn the silence counter there, but the species is region-locked to pale_shelf. The Shardhulk is fielded in all 5 pale_shelf phases (5/15 pools), so its Panic Close is likewise reachable in natural play.

## Technical Receipt

- Initial causal evidence: `data/CombatContent.gd` canon for `pale_shelf_shardshroud_sentinel` (Shardhulk) describes panic-reactive behavior ("expects you to panic", "closes the lane", "Its plates click once before it fires") that no code implemented; like the Glintstalker pre-gen-1 it had only locomotion identity. `EnemyStriker` remains the established HOW boundary for species attack behavior.
- `scenes/combat/EnemyStriker.gd`: the shared static player-cadence clock now also tracks a panic burst (`_panic_burst_count`): pulses with inter-attack gap < SHARD_PANIC_GAP accumulate; crossing SHARD_PANIC_BURST (3) is a new panic episode and re-arms the close (`_shard_close_spent = false`) — further spam inside the same episode does not re-arm; a pulse after a calm gap resets the count. Plus `is_shardhulk` / `shard_panic_armed` / `consume_shard_panic_close` / static `panic_burst_count`; `compute_projectile_damage`, `compute_projectile_speed`, `build_telegraph_profile` accept `shard_active` and apply the SHARD_* constants (species- and behavior-specific). The rule is the deliberate opposite of the Glintstalker's: panic → slower+heavier vs silence → faster+heavier.
- `scenes/combat/ZoneManager.gd`: consumes the close at the same guarantee point as the Glint punish (only once the shot is guaranteed to spawn in `_fire_striker`), prints the `[shard_panic_close]` causal marker (enemy id, species, panic_burst, damage, speed), and emits the readability cues (`proc_feedback_requested` "PLATES CLICK", `screen_flash`) exactly on Lane Close shots. No gen-1 wiring weakened — the glint block is untouched and its suite re-verified green.
- `scenes/combat/CombatScene.gd`: debug-harness witness step mirroring GLINT_PUNISH — seeds a real Shardhulk (`_build_debug_shard_enemy`, live species id), feeds the cadence clock a rapid 3-pulse burst through the REAL `EventBus.player_attacked` wiring, fires through the production path, and asserts the causal telegraph flag (`CONTROL_FOCUS_SEQUENCE SHARD_PANIC_CLOSE`).
- `tools/test_shardhulk_panic_close.gd` (39 checks, 0 failures) runs the production fire path headless: armed panic burst produces a flagged Lane Close with exact damage 15.0 and speed 205.9 (286.0 x 0.72 — asserted slower than base, the opposite of the Glint Shot); one close per episode; calm pulse disarms and fresh burst re-arms; the Glintstalker never fires Lane Closes and the Shardhulk still never fires Glint Shots (the gen-1 invariant re-asserted from the Shardhulk side, silence gap 6.0s); `EventBus.player_attacked` emitted AND connected builds the burst; readability cues fire exactly on close shots; species + locomotion + canon fields authored in live data. Same probe pitfalls as gen-1 honored (runtime class loading; `-1` now-sentinel guarded against backdates).
- `tools/test_glint_natural_spawn_presence.gd` (96 checks, 0 failures) is the retained measurement probe for the gen-1 UNKNOWN. Measured facts (`SPAWN_WEIGHT_FACT` / `SPAWN_MONTE_CARLO` lines in `_visual_proofs/shardhulk_panic_close/runtime_traces.txt`): glint fielded in 4/15 authored phase pools (pale_shelf opening/rising/chorus/final), weight shares 28.00% / 27.12% / 21.67% / 22.41% (6.73% across all pools; 0/5 phases in feeding_hollow, 0/5 in drowned_cut); seeded Monte Carlo (2000 rolls/pool, seed 20261123, through `EncounterIdentityRuntime.pick_weighted_enemy` — the same weight/total algorithm as production `_roll_weighted_entry`'s base) measured 27.90% / 26.10% / 22.00% / 22.50%, each within 1.1pp of the authored share. Shardhulk fielded in 5/15 pools (all pale_shelf phases). Picker-context caveats recorded in the probe header: the live natural picker `EncounterEscalationDirector._pick_pressure_aware_enemy` rolls these authored weights with grade/pressure multipliers (authored share = unmodulated base), and `CombatScene._rehydrate_song_pressure_after_reward` (reward flow only) picks uniformly (33.3/20.0/16.7/16.7% in the containing pools).
- Real runtime witness (headless debug harness, Godot 4.6.1): `debug_harness.bat --debug-control-sequence --debug-autoquit-seconds 60` — N_ATTACK/E_PARRY/S_DODGE/W_ATTACK all PASS, `GLINT_PUNISH PASS` (gen-1 marker intact) and `CONTROL_FOCUS_SEQUENCE SHARD_PANIC_CLOSE PASS shard_flag=true panic_burst=3`, with the causal marker `[shard_panic_close] enemy=9605 species=pale_shelf_shardshroud_sentinel panic_burst=3 damage=15.0 speed=205.9` in the production CombatScene log.
- Real runtime witness (WINDOWED GPU run — the same DebugBootScene WITHOUT --headless, Godot exe directly, env WHAT_WE_FED_DEBUG_PRESET=control_focus / AUTOLAUNCH=1 / AUTOQUIT_SECONDS=90): completed on NVIDIA GeForce RTX 4080 Laptop GPU (OpenGL 3.3 Compatibility), exit 0, all sequence steps PASS including `SHARD_PANIC_CLOSE PASS shard_flag=true panic_burst=3` with the same causal marker. Full windowed log at `_visual_proofs/shardhulk_panic_close/windowed_runtime_traces.txt`; headless harness + both probe outputs at `_visual_proofs/shardhulk_panic_close/runtime_traces.txt`.
- Housekeeping: gen-1's untracked windowed render `_visual_proofs/glint_stalker_silence_punish/rendered_live_run_20261123.png` was inspected (genuine What We Fed DEBUG combat capture) and integrated with its `.import` sidecar rather than abandoned.

## WHAT WE FED Agent Report

Agent: Hermes (Nous Research) — subagent executor
Date: 2026-11-23
Branch/commit if available: master / pending-finish
Task type: Feature (generational extension) + measurement

Files inspected:
- `AGENTS.md`, `CLAUDE.md`, `receipts/receipt_20261123_glint_stalker_silence_punish.md`
- `scenes/combat/EnemyStriker.gd`, `scenes/combat/ZoneManager.gd`, `scenes/combat/CombatScene.gd`, `data/CombatContent.gd`, `data/RegionSongContent.gd`, `systems/EncounterIdentityRuntime.gd`, `systems/EncounterEscalationDirector.gd`, `systems/CreatureLocomotionDirector.gd`, `tools/test_glint_stalker_silence_punish.gd`, `tools/godot.ps1`, `project.godot`

Files changed:
- `scenes/combat/EnemyStriker.gd`
- `scenes/combat/ZoneManager.gd`
- `scenes/combat/CombatScene.gd` (harness-only Shardhulk witness step + seeded debug enemy)
- `tools/test_shardhulk_panic_close.gd` (+ generated `.uid`)
- `tools/test_glint_natural_spawn_presence.gd` (+ generated `.uid`)
- `_visual_proofs/shardhulk_panic_close/runtime_traces.txt`, `_visual_proofs/shardhulk_panic_close/windowed_runtime_traces.txt`
- `_visual_proofs/glint_stalker_silence_punish/rendered_live_run_20261123.png` (+ `.import`) — gen-1 untracked proof integrated
- `receipts/receipt_20261123_shardhulk_panic_close.md`

Validation run: `validate_project.bat` (VALIDATE OK + SUCCESS: Data content is valid); `validate_data.bat` (DATA VALIDATION OK); all twelve `tools/test_*.gd` probes through `tools/godot.ps1 test` — new `test_shardhulk_panic_close` 39 checks / 0 failures, new `test_glint_natural_spawn_presence` 96 checks / 0 failures, `test_glint_stalker_silence_punish` 28 checks / 0 failures (gen-1 unchanged), `test_enemy_pressure_spread` 21 checks / 0 failures, the other eight TEST OK; `debug_harness.bat --debug-control-sequence --debug-autoquit-seconds 60` (all steps PASS incl. both species witnesses); one windowed GPU run of the same DebugBootScene control-focus preset (90s autoquit, exit 0, all steps PASS).

Validation level: 3
Validation result: PASS — deterministic probe coverage of the behavior contract and the spawn measurement, plus headless AND windowed-GPU CombatScene runtime runs whose logs carry the causal markers only the change could produce.

Confirmed repo truth:
- `EnemyStriker` is the HOW boundary for species attack behavior; `ZoneManager._fire_striker` is the single projectile spawn path both species' rules ride; telegraph profile keys merge through `Projectile.tscn` untouched.
- `EventBus.player_attacked` → `ZoneManager._on_player_attacked_pulse` → `EnemyStriker.note_player_attack` is the shared cadence clock both identities read; both species' consume-once semantics live at the same guaranteed-spawn point.
- Natural spawn truth: `RegionSongContent.SONG_PHASES_BY_REGION` authored `weight` fields are the base of production weighted rolls (`EncounterEscalationDirector._roll_weighted_entry`, pressure/grade-modulated); `EncounterIdentityRuntime.pick_weighted_enemy` is the pure weighted owner; `CombatScene._rehydrate_song_pressure_after_reward` picks uniformly.

Unverified assumptions:
- No human/device play-feel assessment: whether the PLATES CLICK telegraph reads at game speed, and whether SHARD_PANIC_GAP=1.0s / burst=3 / 1.5x / 0.72x feel right, is UNKNOWN until Cody plays a Pale Shelf encounter. The windowed run proves GPU-boot + logic only.
- Visual quality of the glacial palette/warning pulse is UNKNOWN — no screenshot of the close shot was captured; claims stop at the flag/parameter level, traces only.
- Independent test authorship was UNVERIFIED: the separate test-making subagent could not be reached from this session, so both probes were authored by the implementation executor (per repo precedent for `tools/test_*.gd`); treat probe expectations as self-authored until independently reviewed.
- The measured weight shares are the authored unmodulated base; how far live grade/pressure multipliers (`_pick_pressure_aware_enemy`) shift them in a real run was not simulated.
- Godot reports `ObjectDB instances leaked at exit` on harness/test shutdown; existing accepted wrapper warnings, root cause not investigated.

Recommended next step: play one Pale Shelf encounter (device or windowed) and tune the SHARD_* constants from the actual player read; consider a Quig pre-meeting line the first time a Lane Close fires in a run.

Risks:
- The panic rule rewards deliberate rhythm and punishes spam; if players read it as random, lower SHARD_PANIC_BURST to 2 or raise SHARD_PANIC_GAP for a wider trigger window — constants are in `EnemyStriker.gd` SHARD_* block.
- Both species share one static cadence clock; if a third species grows a cadence identity, extract the clock to its own owner instead of growing `EnemyStriker` statics further.

## Auditor's Report (v2.5)

- **Task Type**: Feature (generational extension + measurement)
- **Blast Radius**: Tier 2
- **Evidence Type**: Runtime-Verified (headless + windowed GPU)
- **Visual Proof**: `_visual_proofs/shardhulk_panic_close/` — runtime traces only (probe + headless harness + windowed GPU logs with the causal markers); visual/readability quality explicitly UNVERIFIED.
- **Self-Critique Results**:
  - [x] Assumption-Busted (Verified Layer 2 Live Truth — spawn-weight UNKNOWN resolved by measurement over the real data owner, not assumed)
  - [x] Identity Anchor Integrity (Timing/DNA/Beat-Feel — panic rule keys off player attack cadence; per-shot timing windows preserved)
  - [x] Anti-Sludge (Combat-Clean/HUD-Minimal — cues reuse existing banner/flash channels)
  - [x] GDScript 2.0 Compliance (Typing/Signals/EventBus)
  - [x] Signal Tracing (Emitted AND connected — `player_attacked` consumed in ZoneManager, asserted in probe AND harness witness)
  - [x] Null-Safety (@onready/%UniqueName verified)
  - [x] Visual Proof Rule (Screenshots/Logs for visual tasks — visual claims withheld; logs retained)
- **Verified Facts**: Armed panic burst produces a heavier, slower, flagged Lane Close through the production fire path; one close per episode; calm pulses disarm and fresh bursts re-arms; identity is Shardhulk-only and the gen-1 Glintstalker invariants still hold (28/0 green); natural Glintstalker spawn shares measured and Monte-Carlo-confirmed; both harness witnesses observed their causal markers in headless and windowed GPU runs; validators and all twelve probes pass.
- **Unverified Risks**: play-feel, telegraph readability at game speed, visual quality, live multiplier drift on spawn shares, and independent test authorship remain unproven.
- **Next Bounded Move**: one human Pale Shelf play observation to tune the SHARD_* constants from real feel.

## Self-Upgrade Check

- **Repo Truth Changed**: yes — Shardhulk panic identity is live combat behavior; the gen-1 natural-spawn UNKNOWN is now a measured fact with a standing measurement probe.
- **Player Understanding Changed**: yes — the Pale Shelf now teaches two opposite cadence lessons: keep a pulse (Glintstalker) and keep your cool (Shardhulk).
- **Current Pulse Update Needed**: optional — the "Enemy variety needs more readable species identity" gap has a second concrete answer; leave the pulse wording to its owner.
- **Agent Rule Update Needed**: no.
- **New Eval Case Needed**: no — `tools/test_shardhulk_panic_close.gd` and `tools/test_glint_natural_spawn_presence.gd` are the standing regression probes.
- **Soul / Taste Lesson Learned**: yes — the same input (player cadence) yields different species identities when each canon sentence picks its own predicate and its own answer: silence → faster, panic → slower.
- **Recommended Doctrine Patch**: none.
- **One-Sentence Learning**: A second species earns its identity by taking the opposite side of the same truth the first one punishes.
