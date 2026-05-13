# AI ARCHITECTURE LEDGER

Compact boundary map for WHAT WE FED agent architecture. This file is active context, not a historical ledger.

## Authority
1. Locked core and explicit human direction.
2. Current repo truth from inspected files.
3. Current live-build truth from validated runtime/docs.
4. Accepted architecture doctrine.
5. Historical ledgers and archived plans.
6. Future ideas and proposals.

## Active Agent Roles
- **SIGNAL / Vibe-Coder**: tone, identity, anti-generic pressure.
- **BRAIN / Architect**: authority conflicts, architecture boundaries, phase planning.
- **CYBORG / Auditor**: validation, report discipline, workflow hardening.
- **SYMBIOTE / Scout**: repo truth discovery, dependency maps, stale-truth checks.
- **ALFRED / Surgeon**: bounded implementation and local fixes.
- **VISUALS / Inspector**: visual proof, HUD readability, art-doctrine audit.
- **VOID / Crash-Hunter**: runtime validation, crash and smoke-test investigation.

## Routing Rules
- Start with repo truth before proposing implementation.
- Pick one lead lane before acting.
- Use BRAIN for architecture, canon, or multi-system conflicts.
- Use SYMBIOTE when current implementation truth is unclear.
- Use ALFRED only after scope and owner are clear.
- Use VISUALS for UI, art, animation, VFX, readability, enemy/boss presentation, reward presentation, or demo polish.
- Use VOID when a claim depends on runtime behavior, boot health, or crash evidence.

## Confirmed Current Doctrine Sources
- `AGENTS.md`
- `docs/ai/SOVEREIGN_CORE.md`
- `docs/ai/ARCHETYPES.md`
- `docs/ai/REPO_TRUTH_PROTOCOL.md`
- `docs/ai/REPORT_CONTRACT.md`
- `docs/ai/VISUAL_TRUTH_LOOP.md`
- `docs/ai/CURRENT_PULSE.md`
- `docs/ai/LIVING_COMMAND_LOOP.md` — task-completion Evolution Gate and Self-Upgrade Check
- `docs/GAME_SPINE.md`
- `docs/VISUAL_STYLE_GUIDE.md`
- `docs/LIVING_CODEX_PLAYER_VESSEL.md`
- `docs/LOCKBOX_REGISTRY.md`
- `WHAT_WE_FED_LOCKBOX_REGISTRY_FULL.md` as locked reference, not quick active context.

## Human-Only Approval Zones
- Locked core changes.
- Game spine canon changes.
- Architecture doctrine changes.
- Agent role removal or authority-order changes.
- Broad doc pruning, archiving, or migration.
- Protected system rewrites.
- Art-style base doctrine changes.
- Economy, combat, rhythm, or progression spine changes.

## Protected Systems
- `project.godot`
- Scene files (`*.tscn`)
- `autoloads/EventBus.gd`
- Core autoloads and persistent state.
- Combat systems, including `CombatScene.gd`, `PlayerCombat.gd`, `LaneManager.gd` / ZoneManager, and combat presenters.
- Rhythm/timing systems, including `SongConductor.gd`.
- Economy/progression systems, including DNA, Bond/Eat, RunGrowth, RunStats, rewards, collars, tendencies, and world resonance.
- Visual systems and asset/import settings unless a visual task explicitly approves them.
- `data/CombatContent.gd` and other core data registries.

## Current Art Doctrine
- **LEGENDARY PIXEL FABLE INK** is the current base art style.
- Bone Ink / Bonecut Ink is a corruption, Blight, Omen, boss, high-pressure, or late-run layer only.
- Player, creature, and VFX action art is authored down/south by default where applicable.
- Action animation uses idle/base plus one branch frame.
- No authored defeat frames are required.
- Player animations and seven combat backgrounds are already in-game.

## Current Spatial Combat Authority

Do not invent parallel combat management. These are the live owners:

| Director | File | Owns |
|---|---|---|
| ZoneManager | `scenes/combat/ZoneManager.gd` | Spatial registry, spawn placement, projectile/melee spatial execution |
| CombatFireDirector | `systems/CombatFireDirector.gd` | Fire cycle, striker authorization, when/who attacks |
| CreatureLocomotionDirector | `systems/CreatureLocomotionDirector.gd` | Enemy orbit/flank/approach/recoil movement |
| StatusDirector | `systems/StatusDirector.gd` | Status and affliction rules |
| CombatLifecycleDirector | `systems/CombatLifecycleDirector.gd` | Enemy defeat and combat-ended lifecycle |
| SovereignDamageCalculator | `systems/SovereignDamageCalculator.gd` | Damage math |
| PlayerCombat | `scenes/combat/PlayerCombat.gd` | Player action resolution |
| SongConductor | `systems/SongConductor.gd` | Timing truth, beat authority |

Note: `LaneManager.gd` is the Godot filename for ZoneManager. It is retained for UID
safety. The doctrine name is ZoneManager. No agent should describe LaneManager.gd as
"the current spatial authority" — that is stale lane doctrine.

## Known Documentation Risks
- The repo contains hundreds of markdown files, including legacy and archived plans.
- Authority rules are repeated across multiple entrypoints.
- `docs/ai/archive_legacy/truth_history/CURRENT_REPO_TRUTH_LEDGER.md` is too large for active context; kept archived, not deleted (Phase 1 prune, 2026-05-04).
- Engineering rules are fragmented across AI, validation, Godot, and workflow docs.
- Duplicate docs and worktrees can confuse agents.
- Some historical docs contain superseded base-style terms.
- Archived docs may describe deferred or rejected systems as if current.

## Living Command Loop Rule
Every substantial implementation or multi-step report must include the Self-Upgrade
Check section (see `docs/ai/REPORT_CONTRACT.md` section 5 and
`docs/ai/LIVING_COMMAND_LOOP.md`). Agents may update `docs/ai/CURRENT_PULSE.md`
and `tools/ai/evals/wwf_agent_soul_cases.yml` directly when the Evolution Gate
confirms a genuine change. All other doctrine updates require an evolution proposal
and explicit approval.

## Truth Separation Rule
Agents must label and keep separate:
- **Confirmed repo truth**: directly inspected code, scenes, data, or current docs.
- **User-reported truth**: current instruction or report not yet verified in repo.
- **Design direction**: accepted next direction, not necessarily implemented.
- **Future ideas**: proposals, dreams, or deferred scope.

Do not collapse these categories into one claim.

## Evolution Control
- Agents may propose architecture, canon, or doctrine changes in `docs/ai/evolution_proposals/`.
- Agents must not silently update canon or architecture.
- Agents must not implement proposal content without explicit human or Command Center approval.
- Accepted architecture changes must be recorded in `docs/ai/AGENT_EVOLUTION_LOG.md`.
- Broad doc pruning is a later controlled migration, not part of normal implementation.

## Visual Proof Rule
For visual, UI, VFX, art, animation, background, shader, readability, enemy/boss presentation, reward presentation, or demo polish tasks, agents must produce visual proof when technically possible.

Use `_visual_proofs/[task_name]/` or the current visual audit convention, include validation logs when relevant, and never claim visual success without evidence unless capture was technically impossible.
