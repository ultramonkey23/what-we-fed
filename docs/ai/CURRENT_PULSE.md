# CURRENT PULSE

Compact active context for WHAT WE FED agents. Use this before loading massive historical ledgers.

## Current Game State
- Playable pre-alpha foundation.
- Current scenes include TitleScreen, LairScene, RouteScene, and CombatScene.
- Combat is live as readable timing action with attack, parry, dodge, and ultimate.
- The project has moved toward a 360-degree action-RPG hunting field while preserving timing truth and readable threat authority.
- Random song behavior and waveform-based combat modification are live.
- Enemies drop creature-specific DNA.
- Bond/Eat decisions are live.
- A queued reward shell exists.
- Realtime tendency growth is live.
- Ranch is deferred.
- Performance reward depth is a current priority.

## Current Art Doctrine
- **LEGENDARY PIXEL FABLE INK** is the current base style.
- The style target is readable top-down monster-RPG clarity: mythic, strange, wondrous, collectible, slightly eerie, and punchy.
- Bone Ink / Bonecut Ink is only a corruption, Blight, Omen, boss, high-pressure, or late-run layer.
- Player, creature, and VFX action assets are authored down/south by default where applicable.
- Action animation uses idle/base plus one branch frame.
- No authored defeat frames are required.
- Player animations are already in-game.
- Seven combat backgrounds are already in-game.

## Current Demo Strengths
- Core action loop is playable.
- Timing combat has attack/parry/dodge/ultimate language.
- Song pressure can modify combat.
- DNA drops and Bond/Eat give creature-specific stakes.
- Support/growth/reward systems have live foundation pieces.
- Visual Proof Rule is active for visual and demo polish tasks.

## Current Demo Gaps
- Enemy variety needs more readable species identity and pressure spread.
- Boss visuals need stronger authority.
- Impact VFX need clearer power and hit feedback.
- Reward clarity needs stronger score, kill, clean-play, support, and bond/eat payoff.
- Enemy branch frames need more coverage.
- Pickups, DNA, and essence need clearer visual language.
- Tutorial clarity and first-run legibility need more scaffolding.
- Boss presence and authority need stronger moment framing (separate from visual polish).
- Demo packaging and first-impression flow need proof under real first-player conditions.

## Active Director Architecture
- **ZoneManager** — active spatial manager; owns WHEN and WHO coordination. (Godot file: `systems/LaneManager.gd`, retained for UID safety.)
- **CombatFireDirector** — owns fire authority (projectile/attack dispatch).
- **CreatureLocomotionDirector** — owns enemy movement.
- **StatusDirector** — owns status effects.
- **CombatLifecycleDirector** — owns defeat and lifecycle events.
- **SovereignDamageCalculator** — owns damage math.

## Active Soul Anchors (Quig / Identity)
- The player is The Fed Anomaly / Vessel: a non-humanoid, orb-like living anomaly — feeding, bonding, mutating. Not a humanoid, slime, or ghost.
- Quig is the omnipresent fourth-wall-breaking cheerleader/heckler.
- When Quig references the creator or player-as-creator, Quig must call them **"the monkeydog"** — never Cody, the creator, or the developer.

## Recent Important Turns
- Visual Proof Rule became active doctrine for visual, UI, VFX, art, readability, enemy/boss presentation, reward presentation, and demo polish tasks.
- Enemy Purity Phase 1 established `EnemyStriker` as the HOW boundary while ZoneManager / `LaneManager.gd` owns WHEN and WHO coordination.
- ZoneManager naming was adopted for current doctrine while `LaneManager.gd` filename remains for Godot UID safety.
- **Input System Expansion (2026-05-06):** Controller support added. `project.godot` now has full joypad bindings: A/B/X/Y for attack/parry/dodge/support, LB+RB for ultimate, Left Stick for all `mod_*` movement. Tutorial strings in `PresentationTextContent.gd` use tokens (`[ATTACK]`, `[PARRY]`, `[DODGE]`, `[SUPPORT]`, `[ULTIMATE]`, `[MOVE]`) resolved at emit time. `systems/InputHelper.gd` (new) is the static device-detection helper. `systems/QuigNarrativeSystem.gd` gained `trigger_tutorial_line(subcategory)` + `_resolve_tokens()` + `_input()` for device tracking. No combat logic was changed.

## Historical ledger status
Phase 1 documentation prune (2026-05-04) **moved** the long repo truth ledger and related truth snapshots into archive (not deleted):

- `docs/ai/archive_legacy/truth_history/CURRENT_REPO_TRUTH_LEDGER.md`
- `docs/ai/archive_legacy/truth_history/CURRENT_TRUTH_SNAPSHOT.md`
- `docs/ai/archive_legacy/truth_history/SOVEREIGN_HANDOFF.md`

Treat **`docs/ai/CURRENT_PULSE.md`** (this file) plus **`docs/ai/AI_ARCHITECTURE_LEDGER.md`** as the default quick context. Use `docs/ai/AI_ARCHITECTURE_LEDGER.md` for architecture boundaries and `docs/ai/evolution_proposals/README.md` for proposed changes.
