# Glintstalker Silence Punish: reactive species identity in CombatScene

LAB_RECEIPT_CONTRACT_V1:
RESULT: PASS
PROJECT_ID: what-we-fed
MISSION: Give at least one enemy species a distinct observable combat behavior that changes gameplay (not cosmetic-only) in the real CombatScene, plus clearer impact feedback where it serves readability; go beyond the landed locomotion identity in a genuinely different dimension (behavior/encounter dynamics).
ROUTING_DECISION: Lab game-brief trajectory COURSE_CORRECT (MARGINAL_STABILITY, success=0.6667) honored — see Approach Difference.
FILES_CHANGED: scenes/combat/EnemyStriker.gd; scenes/combat/ZoneManager.gd; scenes/combat/CombatScene.gd; tools/test_glint_stalker_silence_punish.gd; tools/test_glint_stalker_silence_punish.gd.uid; _visual_proofs/glint_stalker_silence_punish/; receipts/receipt_20261123_glint_stalker_silence_punish.md
START_HEAD: e8a6f6890e6738dcdc0f98195d3c9f7d851bc03b
END_HEAD: pending-finish
COMMIT: pending-finish
VALIDATION_RESULT: PASS
RECOMMENDED_NEXT_ACTION: Player-observe one Pale Shelf encounter to judge whether the Glint Shot telegraph reads clearly at game speed, and tune GLINT_SILENCE_GAP / multiplier constants from that play report.

## Director Readable

The Glintstalker's canon says "It counts the silence between your pulses. When the gap widens, it stops being a shadow." That identity is now live combat behavior, not flavor text. The Glintstalker reads the player's attack cadence: while the player keeps a pulse, it fires ordinary precision shots. When the silence between player attacks widens past 4 seconds, its next spawned shot is a **Glint Shot** — 1.35x damage, 1.25x projectile speed (a tighter timing window to answer), and a distinct brighter pale-cyan telegraph with a raised warning bias so the punished shot is readable before impact. Exactly one Glint Shot fires per silence gap; a fresh player attack restarts the count. Passive camping is now answered by a specific enemy identity, and keeping a pulse disarms it — a real behavioral counter, wired through the production fire path (ZoneManager.execute_fire -> EnemyStriker -> Projectile.tscn) that CombatScene uses.

Impact/readability feedback rides with the punish: the shot carries `glint_punish` in its telegraph profile (raised `warning_bias` feeds the live lane warning pulse in CombatScene/CombatPresentationController), and when the punish launches the player gets a "THE SILENCE OPENS" proc-feedback banner and a pale-cyan screen flash through the existing CombatScene consumers.

While proving this through the real fire path, a latent defect at HEAD was exposed and repaired: `ZoneManager.start_combat` called `_cache_enemy_scene` before the `EnemyState` existed, so the cache write aborted on a missing-key dictionary access and every start_combat-spawned projectile enemy was handed a null projectile scene (could never fire through `_fire_striker`). `_cache_enemy_scene` now resolves and returns the scene and only writes the cache when a state exists.

## Technical Receipt

- Initial causal evidence: `data/CombatContent.gd` canon for `pale_shelf_precision_stalker` (Glintstalker) describes cadence-reactive behavior ("It counts the silence between your pulses") that no code implemented; the species had only locomotion identity (commit ba9a284). `EnemyStriker` is the established HOW boundary for species attack behavior (ashclaw bleed-synergy precedent).
- `scenes/combat/EnemyStriker.gd`: static player-cadence clock (`mark_combat_start` / `note_player_attack` / `silence_gap`) plus `is_glint_stalker` / `glint_punish_armed` / `consume_glint_punish`; `compute_projectile_damage`, `compute_projectile_speed`, and `build_telegraph_profile` accept `glint_active` and apply the GLINT_* constants (species- and behavior-specific, not global).
- `scenes/combat/ZoneManager.gd`: connects `EventBus.player_attacked` to the cadence clock in `_ready`; resets the clock in `start_combat`; consumes the punish only once a shot is guaranteed to spawn in `_fire_striker`; prints the `[glint_punish]` causal marker and emits the readability cues (`proc_feedback_requested`, `screen_flash`) exactly on punished shots.
- `scenes/combat/ZoneManager.gd` repair: `_cache_enemy_scene` now returns the resolved `PackedScene` and guards the state write; `start_combat` consumes its return value so strikers get a real projectile scene. A throwaway semantics probe (removed after use) proved the missing-key write aborts the callee while the caller continues — the exact silent failure mode at HEAD.
- Sentinel fix discovered during proof: `Time.get_ticks_msec()` is engine uptime, so probe backdates go negative and collided with the `-1 = now` sentinel in `note_player_attack`; only `-1` is special now, and `silence_gap` clamps at zero.
- `tools/test_glint_stalker_silence_punish.gd` (28 checks, 0 failures) runs the production fire path headless: armed silence produces a flagged Glint Shot with exact damage 13.5 and speed 537.5; the punish is spent after one shot; a fresh player pulse disarms it and a fresh widened gap re-arms it; the Shardhulk never fires Glint Shots at any cadence; `EventBus.player_attacked` is emitted AND connected; readability cues fire exactly with punished shots. The probe loads `EnemyStriker` at runtime only — referencing its class_name at `-s` compile time compiles it before autoloads register (`PlayerState` unresolved) and poisons the class for the whole run.
- Real runtime witness (windowed-mode debug harness, headless, Godot 4.6.1): `debug_harness.bat --debug-control-sequence --debug-autoquit-seconds 30` completed N_ATTACK/E_PARRY/S_DODGE/W_ATTACK all PASS plus `CONTROL_FOCUS_SEQUENCE GLINT_PUNISH PASS glint_flag=true silence_gap=4.41s`, with the causal marker `[glint_punish] enemy=9504 species=pale_shelf_precision_stalker silence_gap=4.40s damage=13.5 speed=537.5` in the production CombatScene log. Traces retained at `_visual_proofs/glint_stalker_silence_punish/runtime_traces.txt`.
- Two additional real CombatScene boots through `debug_harness.bat` (normal_boot, pale_shelf region, 20s and 75s autoquit) ran clean (no script errors); no natural Glintstalker spawn fired inside those windows, so the deterministic harness witness above is the runtime proof.
- Probe/test hygiene: the failed-run logs showed Godot exits 0 on script errors while `godot.ps1 test` scans logs, and callee-abort vs caller-continue semantics; both are baked into the probe design.

## WHAT WE FED Agent Report

Agent: Hermes (Nous Research) — subagent executor
Date: 2026-11-23
Branch/commit if available: master / pending-finish
Task type: Feature + defect repair

Files inspected:
- `AGENTS.md`, `CLAUDE.md`, `docs/ai/CURRENT_PULSE.md`
- `scenes/combat/ZoneManager.gd`, `scenes/combat/EnemyStriker.gd`, `scenes/combat/Projectile.gd`, `scenes/combat/CombatScene.gd`, `data/CombatContent.gd`, `data/EnemyTemplates.gd`, `systems/CombatImpactFeedback.gd`, `systems/CreatureLocomotionDirector.gd`, `systems/EnemyState.gd`, `systems/CombatFireDirector.gd`, `autoloads/EventBus.gd`, `autoloads/CombatFeedbackDirector.gd`, `autoloads/DevHarness.gd`, `scenes/dev/DebugBootScene.gd`, `tools/godot.ps1`, `tools/test_enemy_pressure_spread.gd`

Files changed:
- `scenes/combat/EnemyStriker.gd`
- `scenes/combat/ZoneManager.gd`
- `scenes/combat/CombatScene.gd` (harness-only Glintstalker witness step + seeded debug enemy)
- `tools/test_glint_stalker_silence_punish.gd` (+ generated `.uid`)
- `_visual_proofs/glint_stalker_silence_punish/runtime_traces.txt`
- `receipts/receipt_20261123_glint_stalker_silence_punish.md`

Validation run: `validate_project.bat` (VALIDATE OK + data validation SUCCESS, twice — before and after the CombatScene harness edit); `smoke_project.bat` (SMOKE OK); all ten `tools/test_*.gd` probes through `tools/godot.ps1 test` including the new one (new probe 28 checks / 0 failures; `test_enemy_pressure_spread` 21 checks / 0 failures; the other eight TEST OK); `debug_harness.bat --debug-control-sequence --debug-autoquit-seconds 30` (exit 0, all steps PASS); two `debug_harness.bat` normal_boot pale_shelf runs (20s, 75s autoquit, exit 0).

Validation level: 3
Validation result: PASS — deterministic probe coverage of the behavior contract plus a real CombatScene runtime run whose log carries the one causal marker only the change could produce.

Confirmed repo truth:
- `EnemyStriker` is the HOW boundary for species attack behavior; `ZoneManager` decides when/who fires; `Projectile.tscn` renders telegraph identity from the profile dict (all source keys merge through).
- `warning_bias` in a telegraph profile feeds the live lane-warning pressure pulse (CombatScene ~1254, CombatPresentationController ~1524).
- `proc_feedback_requested` and `screen_flash` are connected in CombatScene; the punish cues ride those existing consumers.
- The Glintstalker is authored in live spawn data (`data/RegionSongContent.gd` weighted tables, `data/EnemyTemplates.gd` pale_shelf pools) so real Pale Shelf encounters can field it.

Unverified assumptions:
- No human/device play-feel assessment; whether the Glint Shot telegraph reads clearly at game speed and whether 4.0s / 1.35x / 1.25x constants feel right is UNKNOWN until Cody plays a Pale Shelf encounter.
- Visual quality of the glint palette/warning pulse is UNKNOWN — no screenshot or device capture was taken; claims stop at the flag/parameter level. The `_visual_proofs/` package contains runtime traces only, deliberately no visual claims.
- Independent test authorship was UNVERIFIED: the separate test-making subagent could not be reached from this session, so the probe was authored by the implementation executor (per repo precedent for `tools/test_*.gd`); treat probe expectations as self-authored until independently reviewed.
- Whether natural (non-harness) encounters field Glintstalkers often enough for players to learn the counter is a content-weight question, unmeasured here.
- Godot reports `ObjectDB instances leaked at exit` and one `resources still in use at exit` on harness/test shutdown; existing accepted wrapper warnings, root cause not investigated.

Recommended next step: play one Pale Shelf encounter (device or windowed) and tune the silence gap / punish multipliers from the actual player read; optionally surface a diegetic pre-shot cue (Quig line) the first time the punish fires in a run.

Risks:
- The punish is tuned conservatively (one shot per gap); if passive play still dominates, the gap threshold can widen or the multiplier grow — constants are all in `EnemyStriker.gd` GLINT_* block.
- `start_combat`'s cache repair changes a shared path; the full probe battery plus the control-focus harness pass on the repaired path, but a longer song-run soak was not executed.

## Auditor's Report (v2.5)

- **Task Type**: Feature (with in-line defect repair)
- **Blast Radius**: Tier 2
- **Evidence Type**: Runtime-Verified
- **Visual Proof**: `_visual_proofs/glint_stalker_silence_punish/` — runtime traces only (probe + real CombatScene harness logs with the causal marker); visual/readability quality explicitly UNVERIFIED.
- **Self-Critique Results**:
  - [x] Assumption-Busted (Verified Layer 2 Live Truth — start_combat cache defect found by real execution, not assumed)
  - [x] Identity Anchor Integrity (Timing/DNA/Beat-Feel — punish keys off player attack cadence, timing windows preserved per-shot)
  - [x] Anti-Sludge (Combat-Clean/HUD-Minimal — cues reuse existing banner/flash channels)
  - [x] GDScript 2.0 Compliance (Typing/Signals/EventBus)
  - [x] Signal Tracing (Emitted AND connected — `player_attacked` consumed in ZoneManager; cues consumed in CombatScene; both asserted in probe)
  - [x] Null-Safety (@onready/%UniqueName verified)
  - [x] Visual Proof Rule (Screenshots/Logs for visual tasks — visual claims withheld; logs retained)
- **Verified Facts**: Armed silence produces a faster, heavier, flagged Glint Shot through the production fire path; one punish per gap; player pulses disarm and re-arms on fresh gaps; identity is Glintstalker-only; readability cues fire exactly with punished shots; the real CombatScene harness observed the causal marker; validators and all ten probes pass.
- **Unverified Risks**: play-feel, telegraph readability at game speed, visual quality, natural spawn cadence, and independent test authorship remain unproven.
- **Next Bounded Move**: one human Pale Shelf play observation to tune the GLINT_* constants from real feel.

## Self-Upgrade Check

- **Repo Truth Changed**: yes — Glintstalker cadence identity is live combat behavior; start_combat projectile-scene caching repaired; probe compile-order pitfall documented in `tools/test_glint_stalker_silence_punish.gd` comments.
- **Player Understanding Changed**: yes — silence is now a readable, punishable stance against one species with a visible counter (keep a pulse).
- **Current Pulse Update Needed**: optional — the Demo Gaps line "Enemy variety needs more readable species identity" has one more concrete answer; leave the pulse wording to its owner.
- **Agent Rule Update Needed**: no.
- **New Eval Case Needed**: no — `tools/test_glint_stalker_silence_punish.gd` is the standing regression probe.
- **Soul / Taste Lesson Learned**: yes — a species reads as itself when its canon sentence becomes its rule: the Glintstalker counts the silence, so the code made silence its trigger.
- **Recommended Doctrine Patch**: none.
- **One-Sentence Learning**: Reactive identity beats stat identity: a species becomes memorable when its own lore sentence is the condition its behavior fires on.
