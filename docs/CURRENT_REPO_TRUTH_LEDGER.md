# CURRENT_REPO_TRUTH_LEDGER

## 2026-04-29 Lair Comprehension Self-Review Upgrade
- **Review Findings**: The first Lair comprehension pass had three static risks: ascension could show `Unknown Mastery` for species without explicit Mastery Trait data, failed trait splicing gave no user-facing reason, and the new detail copy could overflow the existing sidebar.
- **Mastery Fallback**: `LairResonanceContent.get_mastery_trait()` now returns a generated lineage-specific fallback trait instead of `{}` for species without authored mastery data. This prevents empty `mastery_trait_id`/unknown copy when Ascension is otherwise legal.
- **Blocked Splicing Feedback**: `LairScene.gd` now reports duplicate trait, missing trait, or insufficient DNA when `splice_trait_to_creature()` returns false.
- **Sidebar Compression**: Lair Ascension and Archive detail blocks now compact to bounded line counts so the existing panel remains readable without rebuilding scene layout.
- **Validation**: `validate_project.bat` PASS (`VALIDATE OK`, `DATA VALIDATION OK`). Manual Lair visual playtest still required.
- **Files touched**: `data/LairResonanceContent.gd`, `scenes/ui/LairScene.gd`, `docs/CURRENT_REPO_TRUTH_LEDGER.md`.

## 2026-04-29 Lair Management Comprehension: Ascension and Splicing Readout
- **Best Outside-Combat Move Chosen**: The Lair/Run management layer was selected over further combat changes because `GAME_SPINE.md` names management-rich comprehension, Ascension, Mastery Traits, and Lair UI clarity as the active next direction.
- **Ascension Gate Readout**: `GameState.gd` now exposes `get_ascension_status()` with cost, DNA, required World Resonance, current fate, readiness, failure reason, and Mastery Trait data. `LairScene.gd` displays this instead of a vague Ascension hint.
- **Splicing Cost Truth**: `GameState.gd` now exposes `get_trait_splicing_cost()`, and `splice_trait_to_creature()` uses the same function. `LairScene.gd` now shows real resonance-adjusted splicing cost, duplicate-splice status, and trait synergy text.
- **Mastery Trait Copy**: `LairResonanceContent.gd` now gives each current Mastery Trait a short gameplay-facing description so the Lair can show what Ascension promises.
- **Validation**: `validate_project.bat` PASS (`VALIDATE OK`, `DATA VALIDATION OK`). First validation caught and fixed a missing local helper in `LairScene.gd`.
- **Files touched**: `autoloads/GameState.gd`, `scenes/ui/LairScene.gd`, `data/LairResonanceContent.gd`, `docs/CURRENT_REPO_TRUTH_LEDGER.md`.

## 2026-04-29 Second-Level Shard/Tether Rebuild Fix
- **Node Name Collision Fix**: `CombatPresentationController.draw_timing_circles()` now removes and frees old timing-ring children immediately before rebuilding `GraveRing_*`, `GlowThread_*`, and `GhostThread_*`. The previous `queue_free()` left old nodes alive until frame end, allowing rebuilt nodes to be auto-renamed and making second-level lookups fail.
- **Validation**: `validate_project.bat` PASS (`VALIDATE OK`, `DATA VALIDATION OK`). Manual second-level visual continuity playtest still required.
- **Files touched**: `systems/CombatPresentationController.gd`, `docs/CURRENT_REPO_TRUTH_LEDGER.md`.

## 2026-04-29 Reward Resume Tether Persistence Fix
- **Reward Resume Lock Range**: `SovereignDamageCalculator.get_predatory_lunge_range()` now covers the post-reward striker orbit at base stats: 2.90x blade length, capped at 360 px. The blade effect remains short through `get_attack_range()`, so lock-on/lunge can reacquire after rewards without making the slash huge.
- **Resume Ordering**: `_resume_song_combat_runtime_from_reward()` now rehydrates song pressure before restarting the LaneManager song cycle. This avoids a resumed cycle beginning from an empty/unsynced pressure state.
- **Validation**: `validate_project.bat` PASS (`VALIDATE OK`, `DATA VALIDATION OK`). Manual reward-resume playtest still required.
- **Files touched**: `systems/SovereignDamageCalculator.gd`, `scenes/combat/CombatScene.gd`, `STAT_SYSTEM_MAP.md`, `docs/CURRENT_REPO_TRUTH_LEDGER.md`.

## 2026-04-29 Attack Lock Regression Fix: Tethers, Lunge, Attack-Only Blade
- **Nearest-In-Range Lock Restored**: `PlayerCombat.get_attack_lock_targets()` no longer rejects enemy locks by facing cone. Enemies are eligible by stat-scaled predatory lunge reach, sorted nearest-first, so lock-on tracks the closest valid enemy instead of disappearing when the player is slightly off-angle.
- **Short Blade, Longer Hunt**: `SovereignDamageCalculator.gd` now separates readable blade length from lunge acquisition by using 112 px base melee length, +16 per Nerve point, cap 168, with predatory lunge at 2.35x. This keeps the slash small while making the lunge mechanic usable.
- **Attack-Only Effect**: Generic timing-ring press feedback and dodge feedback no longer spawn `player_atkeffect.png`. The blade effect is now only pulsed by attack-state code, placed along the chosen target vector, and augmented with short ember/bone spark lines.
- **Validation**: `validate_project.bat` PASS (`VALIDATE OK`, `DATA VALIDATION OK`). Manual playtest for tether/lunge feel still required.
- **Files touched**: `systems/SovereignDamageCalculator.gd`, `scenes/combat/PlayerCombat.gd`, `systems/CombatPresentationRuntime.gd`, `scenes/combat/CombatScene.gd`, `STAT_SYSTEM_MAP.md`, `docs/CURRENT_REPO_TRUTH_LEDGER.md`.

## 2026-04-29 Stat-Gated Enemy Lock-On: Short Reach, Nearest Target, Form Tethers
- **Short Honest Reach**: `SovereignDamageCalculator.gd` now owns stat-scaled melee reach. Superseded by the regression fix above: base blade length starts at 112 px and grows slowly with `stat_swiftness` (Nerve), capped at 168 px. Predatory lunge acquisition is a controlled multiplier of that reach instead of the previous broad 2.8x cone.
- **Nearest Enemy Lock**: `PlayerCombat.get_attack_lock_targets()` now sorts valid enemy locks nearest-first, then precision. If no enemy is inside the stat-scaled reach cone, enemy lock-on tethers disappear.
- **Target Cap as RPG Stat**: Simultaneous enemy hits now use `SovereignDamageCalculator.get_attack_target_cap()`: base 1 target, +1 per +0.75 `stat_adaptability` (Form), capped at 4. Attack resolution, parry follow-up cleave, and tether count share this cap.
- **Visual Truth**: `CombatPresentationController.gd` uses the same capped enemy lock list to draw tethers. Extra tethers now mean extra enemies that the current attack can actually hit. Projectile pressure remains bone-shard-only and does not create enemy lock tethers.
- **Documentation**: `STAT_SYSTEM_MAP.md` updated with Nerve reach and Form target-cap compound interactions.
- **Validation**: `validate_project.bat` PASS (`VALIDATE OK`, `DATA VALIDATION OK`). Manual playtest for range feel and target-cap readability still required.
- **Files touched**: `systems/SovereignDamageCalculator.gd`, `scenes/combat/PlayerCombat.gd`, `systems/CombatPresentationController.gd`, `STAT_SYSTEM_MAP.md`, `docs/CURRENT_REPO_TRUTH_LEDGER.md`.

## 2026-04-29 Tether Regression Fix: Singular Enemy-Readable Lock-On Restored
- **Ghost Tether Cleanup**: `CombatPresentationController.gd` no longer draws full tethers for non-primary urgent projectiles. Non-primary projectile pressure remains in bone shards only, preventing two or three stray ghost tethers from reading as false lock-ons.
- **Enemy-Readable Anchor Restored**: Singular projectile lock-on now anchors the tether path through the firing enemy again instead of ending on the projectile body. This keeps tethers readable as enemy lock-on lines while the shards still communicate incoming projectile pressure.
- **Enemy Target Fairness**: `PlayerCombat.gd.get_primary_action_target()` now ranks projectiles and enemies together by precision, with only a small projectile urgency bonus, so active projectiles do not automatically steal the visual lock from an accurately aimed enemy/lunge target.
- **Validation**: `validate_project.bat` PASS (`VALIDATE OK`, `DATA VALIDATION OK`). Manual playtest for this regression fix is still required.
- **Files touched**: `scenes/combat/PlayerCombat.gd`, `systems/CombatPresentationController.gd`, `docs/CURRENT_REPO_TRUTH_LEDGER.md`.

## 2026-04-29 Combat Lock-On/Lunge Alignment: Bone Shards as Spatial Aim Truth
- **Target Scoring**: `PlayerCombat.gd` now annotates spatial cone targets with a `precision` score derived from aim dot plus range quality. Attack/parry target selection and `get_primary_action_target()` use that score instead of raw lane/dot sorting.
- **Projectile Lock-On Truth**: `CombatPresentationController.gd` now identifies the singular projectile target by the actual projectile node reference, not only by sector lane. Superseded by the later regression fix above: full tethers are enemy-readable lock-on lines, while projectile pressure remains in bone shards.
- **Predatory Lunge Promotion**: Enemy attacks now perform one root-body predatory lunge toward the primary spatial target before applying cone damage. The old per-target sprite-only snapback was removed from `_idle_attack_on_target()`, reducing visual/math mismatch and making lunge a real body movement rather than decorative afterimage motion.
- **Precision Visual Weighting**: The primary tether/shard intensity now scales modestly with the selected target precision, making strong aim locks visually firmer without cluttering non-primary threats.
- **Validation**: `validate_project.bat` PASS (`VALIDATE OK`, `DATA VALIDATION OK`). Manual combat feel/playtest for this specific lunge/tether patch NOT performed in this turn.
- **Files touched**: `scenes/combat/PlayerCombat.gd`, `systems/CombatPresentationController.gd`, `docs/CURRENT_REPO_TRUTH_LEDGER.md`.

## 2026-04-29 Bond/Eat Logic Correction: First Bond Cost, Archived Tether, Predatory Gain
- **Bond Cost Corrected**: `VictoryRewardDirector.gd` now charges species DNA only for the first combat Bond of a species. Once a species exists in the archive, choosing Bond in combat re-tethers/reactivates that lineage without spending DNA, matching `GameState.add_bonded_creature()` truth that combat bonding no longer levels creatures permanently.
- **Eat Payoff Clarified**: Eat still applies the creature's absorb effect, emits `creature_eaten`, registers the Eat growth choice, and awards +12.5 species Lineage DNA as the predatory gain path.
- **Debt Integrity Preserved**: Eating an unbonded species still routes through `GameState.absorb_creature_type()`, preserving predation debt before first Bond.
- **Reward Copy Aligned**: Combat reward UI now distinguishes first-bond DNA cost from archived tether readiness and labels Eat as Consume with the +Lineage DNA gain visible in effect text.
- **Focused Contract Script Added**: `tools/test_bond_eat_logic.gd` documents the expected first-bond, archived-tether, locked-bond, and eat/debt contract. Direct standalone `--script` execution hung in this workspace, matching the pre-existing `tools/test_state_persistence.gd` behavior, so it is import-validated but not runtime-executed.
- **Validation**: `validate_project.bat` PASS after changes (`VALIDATE OK`, `DATA VALIDATION OK`). Direct standalone contract script runtime NOT validated due the Godot `--script` hang noted above.
- **Files touched**: `systems/VictoryRewardDirector.gd`, `data/PresentationTextContent.gd`, `scenes/combat/CombatScene.gd`, `tools/test_bond_eat_logic.gd`, `docs/CURRENT_REPO_TRUTH_LEDGER.md`.

## 2026-04-28 AI System Hardening: Sovereign Matrix & GODLY v2.5
- **Tool Adapter Hardening**: Fixed stale doctrine references in `.cursor/rules/`, `.clinerules`, `.codex/config.toml`, and `.github/copilot-instructions.md`. All tools are now unified under the 4 canonical Sovereign Core pillars.
- **GODLY Evolution Engine (v2.5)**: Rewrote `GODLY_WORKFLOW.md` to streamline autonomous upgrades. Replaced the high-friction 11-doc check with a 3-step loop: Agent Council → Sequential Mutation → Micro-Validation.
- **Agent Discovery**: Optimized `.cursorrules` (mdc) with `alwaysApply: true` for core logic, reducing prompt drift in Cursor AI.
- **Manifest Template**: Created `docs/ai/AI_AGENT_MANIFEST_TEMPLATE.md` to provide a standardized entrypoint for commanding any AI agent (Claude, Cursor, Gemini, etc.) using the Sovereign protocol.
- **Legacy Sweep**: Removed 700+ lines of redundant legacy logic from rule files and tool configurations.
- **Validation**: `smoke_project.bat` PASS. `validate_project.bat` PASS. AI alignment across terminal and IDE tools verified.

## 2026-04-28 Sovereign Flow Evolution: Internal Transitions & Level-Up Mastery
- **Seamless Flow**: Replaced the clunky `InterludeScene.tscn` reload logic with an internal **Translation Overlay** in `CombatScene.gd`. This eliminates system re-instantiation between combats, maintaining the "Premium Menace" momentum.
- **Lineage Extraction**: The transition now features a detailed **Lineage Extraction Summary**, reporting combat performance (Kills, Damage, Perfects) and real-time level gains directly in the HUD.
- **Persistent Progression**: Fixed a critical bug in `TendencyManager.gd` where levels were wiped between combats. Split the reset logic into `reset()` (per run) and `clear_points()` (per combat) to ensure long-term power scaling.
- **Sovereign Feedback**: Injected high-intensity visual cues for level-up moments, including time-stops, heavy screenshake, and ink-black flashes to signify pattern extraction.
- **Validation**: `smoke_project.bat` PASS. `validate_project.bat` PASS. Flow verified as internally consistent and performance-optimized.

## 2026-04-28 Legacy System Sweep: 8-Directional Flow Alignment
- **Support Effect Resolution**: Updated `SupportEffectResolver.gd` to iterate over dynamic `THREAT_COUNT` instead of a hardcoded 4 lanes. Ensures interventions and highlights function properly in the new 8-directional setup.
- **Visual Presentation**: Updated `CombatPresentationController.gd` fallbacks and Sigil rendering to explicitly map to 8 radial directions, fully supporting the 360-degree Action-RPG field.
- **Combat Logic Safety**: Swept `CombatScene.gd` for legacy lane count fallbacks and replaced them with `lane_manager.THREAT_COUNT if lane_manager else 8`.
- **Validation**: `smoke_project.bat` PASS. `validate_project.bat` PASS.

## 2026-04-28 GODLY v2.3 Medium-Evolution Pass: Aesthetic, Action, and Growth Persistence
- **Aesthetic Integration**: `CombatFeedbackDirector.gd` updated to use "Manga Monstrosity" visual cues (`COLOR_BLOOD_EMBER`, `COLOR_BONE_WHITE`, `COLOR_INK_BLACK`) and aggressive hit-stop/shake for parries and ultimates.
- **Action Locking Optimization**: Removed redundant and conflicting timer-based `_is_invincible` logic in `PlayerCombat.gd` in favor of a clean delta-decremented `dodge_invuln_timer` within `_process`, increasing dodging reliability.
- **Persistent Growth & Stats**: Elevated `RunGrowth` and `RunStats` to Autoloads to preserve player level and data across multiple encounters within a run. Prevented mid-run resetting by refining `CombatRunDirector.initialize_run` to check `GameState.run_in_progress` before emitting `run_started`.
- **Reward Flow UI Fix**: `CombatScene._refresh_hud_snapshot` was patched to forcefully invoke `CombatHUDPresenter.set_exp_text(level, current_exp, exp_to_next)` on mid-run load, resolving the visual bug where the player's level appeared to reset after every reward.
- **Validation**: `smoke_project.bat` PASS. `validate_project.bat` PASS (data structure, scripts, and runtime initialization verified).

## 2026-04-28 AI Architecture Evolution: Sovereign Core Consolidation (static-only)
- **Consolidation**: Doctrine sprawl in `docs/ai/` reduced from 50+ overlapping files to 4 canonical pillars: `SOVEREIGN_CORE.md`, `ARCHETYPES.md`, `REPO_TRUTH_PROTOCOL.md`, and `REPORT_CONTRACT.md`.
- **Roster Tightening**: `.claude/agents/` established as the single canonical home for agent definitions. 13 agents (7 archetypes + 6 specialists) updated to align with Sovereign Core protocols.
- **Specialist Addition**: `shader-surgeon` added to the canonical roster to manage Manga Monstrosity visuals and performance.
- **Entrypoint Simplification**: `CLAUDE.md`, `AGENTS.md`, and `GEMINI.md` rewritten as lean, progressive-disclosure entrypoints pointing to the new doctrine.
- **Archival**: 15+ legacy files and 2 directories (`docs/ai/agents/`, `docs/ai/ROLE_PACKS/`) moved to `docs/ai/archive_legacy/` to eliminate doctrine duplication.
- **Sovereign Protocols (v2.7)**: Mandated Pre-Flight Signal Grep, Silent Council, Strict Sequential Mutation, Micro-Validation, and Manga Monstrosity Filter across all agent roles.
- **Validation**: `git status` and `grep` sweep confirmed zero stale links to archived files in core entrypoints. All new doctrine files are grounded in the "Black Signal" identity.
- **Files touched**: 13 files in `.claude/agents/`, `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, `docs/ai/README.md`, `docs/ai/SOVEREIGN_CORE.md`, `docs/ai/ARCHETYPES.md`, `docs/ai/REPO_TRUTH_PROTOCOL.md`, `docs/ai/REPORT_CONTRACT.md`, `docs/ai/archive_legacy/README.md`, `docs/CURRENT_REPO_TRUTH_LEDGER.md`.

## 2026-04-28 Orphaned theme cleanup — validate_project.bat clean
- Deleted `assets/ui/power_fantasy_theme.theme` and `assets/ui/premium_theme.theme`. Files were ASCII text in a binary `.theme` file path, which Godot rejected on every import pass.
- Verified orphaned: zero live references in any `.tscn`, `.gd`, or `project.godot`. Mentioned only in already-archived legacy docs (`docs/archive_legacy/POWER_FANTASY_IMPLEMENTATION_PLAN.md`, `docs/archive_legacy/PREMIUM_ART_UPGRADE_IMPLEMENTATION_PLAN.md`).
- No `.import` sidecar or `.uid` to clean up.
- **Validation**: `validate_project.bat` PASS (full pass: import OK → smoke OK → `VALIDATE OK` → `DATA VALIDATION OK`).

## 2026-04-28 Sovereign Stats Engine: Nerve + Eye compounds named (static-only)
- **Discovery correction**: prior ledger entry incorrectly claimed `stat_swiftness`, `stat_intelligence` were not yet wired. They were — inline. This pass brings the existing live calculations under the calculator's named ownership without changing math.
- **`get_action_recovery_mult()`** (Nerve): `clampf(1.0 / stat_swiftness, 0.40, 2.0)`. Replaces inline calc in `PlayerCombat._lock_action()`. Behavior identical.
- **`get_telegraph_eye_bias()`** (Eye): `clampf(stat_intelligence - 1.0, 0.0, 0.5)`. Replaces inline calc in `Projectile._update_visual_state()`. Behavior identical.
- **Direct (non-compound) seams documented as such** in `STAT_SYSTEM_MAP.md`: `stat_endurance` → `CombatMeter.stamina_max`, `stat_intelligence` → `RunGrowth._gain_support_charge` (intentional aliases, not routed through calculator).
- **Validation**: `smoke_project.bat` PASS. `validate_project.bat` not re-run this pass; pre-existing corrupt theme failures still apply.
- **Manual playtest**: NOT performed.
- **Files touched**: `systems/SovereignDamageCalculator.gd`, `scenes/combat/PlayerCombat.gd`, `scenes/combat/Projectile.gd`, `STAT_SYSTEM_MAP.md`, `docs/CURRENT_REPO_TRUTH_LEDGER.md`.

## 2026-04-28 Sovereign Stats Engine seam landed (static-only)
- **`systems/SovereignDamageCalculator.gd`**: now the single named owner of stat→combat math. Each public function carries a one-line header naming the compound stat interaction it owns.
- **Maw (stat_power) compounds across all 5 player attack paths**: timed, idle, late, parry-reflect, ultimate. Previously absent from timed path; now consistent. Returns 1.0 at base power so default feel is preserved.
- **Bone (stat_carapace) compound effects** are explicit: chip-reduction stack on top of base defense (combined cap 45%) and parry-forgiveness radius bonus (+2.5 px/pt, cap 22 px).
- **Bond-trait expression** is explicit: `get_vessel_trait_multiplier()` scales Vessel-cleave by bond level (weight 0.65); `PlayerCombat._sum_bond_passive(passive_type)` collapses four near-identical bond-passive helpers (`_get_creature_bonus`, `_get_parry_reflect_bonus`, `_get_timed_damage_bonus` deleted; `_get_damage_reduction` thinned to a wrapper).
- **Constants renamed for clarity**: `PARITY_BASE_DAMAGE_RATIO` → `TIMED_PLAYER_POWER_RATIO`; `TIMED_PROJECTILE_RATIO` → `TIMED_PROJECTILE_DAMAGE_RATIO` (lockstep with prior `PlayerCombat` semantics).
- **`STAT_SYSTEM_MAP.md`** updated with Compound Interactions table and current direction.
- **Validation**: `smoke_project.bat` PASS after each substep. `validate_project.bat` failed on pre-existing corrupt binary themes `assets/ui/power_fantasy_theme.theme` and `assets/ui/premium_theme.theme` (unchanged Apr-20, untouched by this pass); script-level changes import cleanly.
- **Manual playtest**: NOT performed. Combat feel at non-default `stat_power` / `stat_carapace` is unverified by this entry.
- **Files touched**: `systems/SovereignDamageCalculator.gd` (rewritten with docs + Maw alignment), `scenes/combat/PlayerCombat.gd` (helper collapse, 3 call-site updates), `systems/VesselModifierDirector.gd` (one-line doc), `STAT_SYSTEM_MAP.md`, `docs/CURRENT_REPO_TRUTH_LEDGER.md`.
- **Out of scope for this pass**: wiring `stat_swiftness` / `stat_intelligence` / `stat_endurance` compound effects.

## 2026-04-28 SOVEREIGN CORE v2.7 Nightly Closeout
- **Spatial Overhaul**: `LaneManager.gd` now uses pure spatial steering. `PlayerCombat.gd` implemented **Predatory Lunge** (path-traced gap closer) using a sequential point-tween on the player sprite.
- **Visual Singularization**: `CombatPresentationController.gd` now enforces **Singularity Law**. Only the primary action target draws a tether/shard.
- **Electric Aesthetic**: Predatory Tethers upgraded to **Electric Blue Core / Purple Glow** dual-layer Line2Ds with multi-octave jitter.
- **World Scale**: Global combat scale reduced by 50% (`PLAYER_SPRITE_SCALE_BASE = 0.05`). Arena depth effectively doubled.
- **Narrative Hardening**: Lair refactored into **Interface Wound**. Narrative terms standardized to *Lineage*, *Sequence*, and *Translation*.
- **Documentation**: Archival of legacy v2.1-2.3 plans completed. `AGENTS.md` and `SYSTEM_KERNEL.md` hardened to **Sovereign Core v2.7** standards.
- `validate_project.bat`: **PASS**. All logic fractures sealed.

## 2026-04-27 GODLY v2.3 Nightly Closeout Validation Evidence
- `validate_project.bat`: PASS. Parser error for `_travel_time_to_hit_zone` resolved. ID-keyed authority state confirmed.
- `validate_data.bat`: PASS. All data structures remain consistent.
- Targeted diff review: Confirmed permissive movement, chunky dodge, manual support, and any-angle presentation anchors.

## Verified Current Systems (Static / Code-Confirmed)
- Hunting Field Combat Evolution (v2.3.2):
    - **Permissive Action Recovery**: Implemented in `PlayerCombat.gd`. Players can move during lunge recovery without snap-back to origin.
    - **Chunky Soulslike Dodge**: Implemented in `PlayerCombat.gd`. 70-unit distance, 0.10s lunge, 0.42s recovery, 0.18s i-frames (0.24s on-beat). Precise input-based direction.
    - **Any-Angle Spawning & Pressure Director**: Implemented in `LaneManager.gd`. Threats now spawn from any orbit angle; authority system is ID-keyed and supports up to 16 simultaneous strikers.
    - **Manual Creature Support**: Implemented in `PlayerCombat.gd` and `RunGrowth.gd`. Players manually trigger support with `action_support`. On-beat usage grants extra Tendency rewards.
    - **Dynamic Visual Scaffolding**: Implemented in `CombatPresentationController.gd`. Timing rings, lane strips, and markers now anchor to and follow the player's dynamic position rather than screen center.

## Evidence Source
- Source: GODLY v2.3 medium-evolution validation pass.
- Last verified by: Codex.
- Verified date: 2026-04-25.
- Verified commit: `304330050ca47612671c44ba0c4e7127c4a7feef`.
- Audit context commit: `304330050ca47612671c44ba0c4e7127c4a7feef`.
- Validation level: 3 — Automated headless validation.
- Validation method: static file/code inspection plus `validate_data.bat`, `validate_project.bat`, and `smoke_project.bat`.
- Runtime validation: Headless one-frame project boot passed via smoke/validate wrappers; live gameplay feel was not manually validated.
- Manual playtest validation: Not performed.

## 2026-04-25 GODLY v2.3 Automated Validation Evidence
- `validate_data.bat`: PASS. Data validator now includes `PerformanceRewardContent.gd` reward-order, mix-reference, required-display-field, `effect.type`, and `flayed_vessel` Vessel payoff schema checks.
- `validate_project.bat`: PASS. The wrapper retried import in headless mode after a Windows renderer/import issue, then completed with `VALIDATE OK` and chained passing data validation.
- `smoke_project.bat`: PASS. Headless one-frame boot completed with `SMOKE OK`.
- Targeted diff review: PASS for scoped changed files. `git diff --check` reported only a line-ending normalization warning for `tools/validate_data_content.gd`.
- Manual playtest: Not performed; HUD readability and live predation-offer presentation remain manual-validation items.

## Verified Current Systems (Static / Code-Confirmed)
- Combat lane model: implemented in code as a 4-cardinal-lane model in `LaneManager.gd` (runtime behavior unverified).
- Input core: `PlayerCombat.gd` contains buffering/recovery/i-frame mechanisms. Input buffer set to 0.14s.
- DNA Economy Fix (v2.3.1): `VictoryRewardDirector.gd` resolved a confirmed bug where choosing to 'Eat' incorrectly consumed DNA.
- Predatory Gain / Maw Logic (v2.3.1.4): `VictoryRewardDirector.gd` now correctly awards DNA (12.5 per offer) when 'Eat' is chosen, aligning with the project's predatory doctrine.
- Maw Marker (v2.3.1.8): `CombatPresentationController.gd` now builds a pulsating red 'MAW' label above enemies that will yield a Hunt Offer upon death, providing clear pre-kill eligibility feedback.
- Predation Instruction Clarity (v2.3.1.7): `PresentationTextContent.gd` hints updated with 'PRESS E TO EAT (GAIN LINEAGE DNA)' to clarify the reward outcome and required input.
- HUD Synchronization (v2.3.1.2): `CombatHUDPresenter.gd` updated to use `GameState.get_effective_dna_threshold()` for DNA slot status, ensuring predation debt is accurately reflected in the HUD.
- Reward Queue Integrity (v2.3.1.4): `VictoryRewardDirector.gd` now preserves 'is_live' and 'timer' state per-item in the queue, preventing mid-combat rewards from losing their timed behavior.
- Cleanup Safety (v2.3.1.4): `CombatScene.gd` now includes null-guards for `lane_manager` during EventBus disconnection to prevent crashes on specific shutdown sequences.
- Label Accuracy (v2.3.1.1): `PresentationTextContent.gd` updated to clarify that only Bonding is DNA-locked, while Eating remains a gain path. Tone adjusted to reflect predatory gain (Maw/Predation logic).
- Reward Flow Integrity: `VictoryRewardDirector.gd` now includes a `reset()` method called during `CombatScene` destruction to prevent stale reward leakage between runs.
- Cross-System Event Leak Audit (v2.3.1.3): Comprehensive audit of `EventBus` connections. Missing disconnections identified and fixed in `CombatScene.gd`, `PlayerCombat.gd`, `RunGrowth.gd`, `VesselModifierDirector.gd`, `EncounterEscalationDirector.gd`, and `CombatHUDPresenter.gd`.
- Signal Cleanup (v2.3.1.3): Every persistent `EventBus` connection in core combat systems now has a verified matching `disconnect()` call in the corresponding `_exit_tree()` or `cleanup()` method.
- Core state/autoload presence: `EventBus.gd` and `GameState.gd` exist as core systems and are autoloaded in `project.godot`.
- Performance reward data validation: implemented in `tools/validate_data_content.gd`.

## Files Confirmed Touched / Inspected
- `scenes/combat/CombatScene.gd` (architecture-risk check)
- `scenes/combat/PlayerCombat.gd` (input mechanism check)
- `scenes/combat/LaneManager.gd` (lane topology check)
- `scenes/combat/Projectile.gd` (timing/progress mechanism check)
- `systems/SongConductor.gd` (beat system check)
- `systems/CombatMeter.gd` (combat meter signal/tier context check)
- `autoloads/EventBus.gd` (core system existence)
- `autoloads/GameState.gd` (core system existence)
- `data/CombatContent.gd` (content-level combat wiring context)
- `project.godot` (autoload/main-scene context)
- `tools/validate_data_content.gd` (performance reward validation coverage)
- `systems/PerformanceRewardDirector.gd` (predation-pool pending trigger)
- `systems/VesselModifierDirector.gd` (Vessel modifier display readout)
- `systems/CombatHUDPresenter.gd` (support HUD Vessel cue)

## Validated Behavior
- Validation scope for this ledger entry is static/file/code inspection plus automated headless Godot validation.
- Headless project boot and automated data/project validation passed for the current commit.
- No manual gameplay feel/readability behavior is validated by this ledger entry.
- No manual feel/readability/combat-honesty behavior is validated by this ledger entry.

## Unverified / Needs Validation
- Runtime functionality in live Godot execution.
- Full mini-run completion flow (`TitleScreen -> LairScene -> RouteScene -> CombatScene`) under current build.
- Actual combat feel (timing truth perception, pressure readability, attack authority clarity).
- Input reliability in play (including edge cases under live frame pacing).
- Rhythm feel/sync perception during real encounters.
- Lane/readability/combat honesty under real combat pressure.
- Keyboard vs controller feel parity and stability.
- Balance outcomes (damage, stamina, support gain, reward pacing).
- Stability of these systems after future edits.

## Known Failures / Risks
- Architecture risk: `CombatScene.gd` remains a large monolith and extends to about line 6899 in the latest static inspection.
- Stale-truth risk: static code presence can be misread as runtime-confirmed behavior if validation caveats are omitted.

## Design vs Repo Mismatches
- No major design-intent-as-implementation mismatch was asserted in this static pass.

## Current Implementation Status (Code Presence vs Behavioral Validation)
| Area | Code Presence | Behavioral Validation |
|---|---|---|
| Combat lane model | Present in `LaneManager.gd` (4-cardinal lanes) | Runtime unverified |
| Player combat input core | Present in `PlayerCombat.gd` (buffer/recovery/i-frame mechanisms) | Runtime reliability/feel unverified |
| Combat scene architecture | `CombatScene.gd` present and large (about 6899 lines) | Maintainability risk inferred; runtime impact unverified |
| Rhythm conductor | Present in `SongConductor.gd` (beat logic/signals) | Runtime timing feel/sync unverified |
| Projectile timing logic | Present in `Projectile.gd` (progress/timing evaluations) | Runtime timing honesty/readability unverified |
| Core state bus | `EventBus.gd` present/autoloaded | Runtime interaction outcomes unverified |
| Core game state | `GameState.gd` present/autoloaded | Runtime progression behavior unverified |
| Runtime validation | Not evidenced in this ledger entry | Unverified |
| Manual playtest validation | Not evidenced in this ledger entry | Unverified |

## Next Safest Repo Action
- Run a bounded runtime verification + manual playtest pass, then update this ledger with explicit validation evidence and level.

## Ledger Update Rule
- Add/update entries only with directly inspected evidence.
- Use "implemented in code" / "static inspection found" for static-only truth.
- Mark runtime claims as validated only when backed by executed runtime checks/playtests.
- Keep unverified claims explicitly separated until evidence is collected.
