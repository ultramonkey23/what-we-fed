# AGENTS — WHAT WE FED

Master contract for AI agents (Claude, Cursor, Gemini, Codex, Cline). **Read the Trinity first**, then branch as needed.

## Read first (Trinity)
1. [docs/ai/SOVEREIGN_CORE.md](docs/ai/SOVEREIGN_CORE.md) — laws, routing, validation posture  
2. [docs/ai/AI_ARCHITECTURE_LEDGER.md](docs/ai/AI_ARCHITECTURE_LEDGER.md) — AI architecture boundaries  
3. [docs/ai/CURRENT_PULSE.md](docs/ai/CURRENT_PULSE.md) — compact **active** current truth (prefer over historical ledgers)

Then: pick a lead lane from [ARCHETYPES.md](docs/ai/ARCHETYPES.md), scan real repo files before implementation, and follow [REPO_TRUTH_PROTOCOL.md](docs/ai/REPO_TRUTH_PROTOCOL.md).

## Project soul
- **Identity**: The Living Codex. **Art**: Legendary Pixel Fable Ink. **Tone**: Mythic, weird, punchy.  
- **Rules**: Timing truth, spatial purity, sequential mutation (see Sovereign Core).

## Visual proof
For visual/UI/VFX work, produce evidence under `_visual_proofs/[task_name]/`.

## Controlled evolution
Architecture, canon, or doctrine changes go through [docs/ai/evolution_proposals/README.md](docs/ai/evolution_proposals/README.md) — do not silently rewrite canon.

## Combat HUD (orientation)
HUD layout largely in `CombatScene.gd`; refresh/presenter binding in `CombatHUDPresenter.gd`. Extra HUD handoff detail (archived): [SOVEREIGN_HANDOFF.md — Combat HUD presenter](docs/ai/archive_legacy/truth_history/SOVEREIGN_HANDOFF.md#combat-hud-presenter-living-boundary).

## Reporting & validation
- End implementation turns with the **Auditor's Report** per [REPORT_CONTRACT.md](docs/ai/REPORT_CONTRACT.md).  
- Run `smoke_project.bat` / `validate_project.bat` when applicable; never claim validation you did not run.
