# CLAUDE.md - WHAT WE FED

Claude Code starts here. Keep this file short; load procedures through `.claude/skills/` and route specialist work through `.claude/agents/`.

## Authority
1. Creator authority: the user is final.
2. Repo truth: current implementation reality.
3. Current live-build truth: what actually boots and plays now.
4. Evolving spine: accepted near-term direction.
5. Older canon/source docs: useful memory, never allowed to fight stronger truth.
6. Dream scope: deferred until explicitly pulled forward.

## Locked Core
Protect the **Living Codex** identity: the player is a sentient System that extracts traits. Maintain **Manga Framing** (high-impact hit-stop/shake) and **Cosmic Horror** weirdness. Ensure **Spatial Purity**: lanes are strictly spawn anchors; all mechanical interaction (Attack, Parry, Support, Ultimate) is 360-degree spatial or ID-authoritative. Protect the **DNA Economy** (predation-based) and **Deterministic Growth** (playstyle dictates stats). 

## Current Working Truth
- Godot 4.6 project. Live flow: `TitleScreen -> Lair -> Route -> Combat`.
- **Combat is 100% Spatial Action-RPG**: Snapping is removed. The **Energy Sword** defines mechanical reach (220.0 units).
- **The System**: Codex Level (10,000 ceiling, meta-cap at 100) and Creature Classes (stat packages) are live.
- **Feedback**: Global "Juice" orchestrated by `CombatFeedbackDirector` (hit-stop, heavy shake).
- **State**: `potential` and `luck` are Meta-Stats; all others reset per run but are modified by permanent Lair Bonds.

## Agent Routing
- **VIBE-CODER** co-creates: ideation, style sharpening, identity protection, signal extraction.
- **BRAIN** decides: strategy, scope, authority conflicts, best next move.
- **SYMBIOTE** connects: repo truth scans, dependency maps, stale-doc reconciliation.
- **CYBORG** upgrades/extracts: validation, hardening, maintainability, workflow infrastructure.
- **ALFRED** simplifies: surgical implementation, bug fixes, usability, handoffs.

Future prompts should name the best-fit agent explicitly. If the prompt does not, select one before acting and state the routing briefly.

## Validation Commands
Run from repo root:
- `smoke_project.bat`: fast headless boot check.
- `validate_data.bat`: content/data integrity audit.
- `validate_project.bat`: import pass, smoke boot, and data audit.
- `debug_harness.bat`: dev-only combat harness.
- `run_project.bat`: interactive game launch.

Do not claim gameplay feel validation from smoke/validate alone. State exactly what was and was not run.

## Load-On-Demand Context
- Shared multi-AI contract: `docs/ai/MULTI_AI_OPERATING_LAYER.md`
- Workflow and validation details: `PROJECT_SETUP_AND_VALIDATION.md`
- System ownership map: `REPO_SYSTEM_MAP.md`
- Current spine: `docs/GAME_SPINE.md`, `docs/NEXT_PHASE_PLAN.md`
- Deep AI doctrine: `docs/ai/SYSTEM_KERNEL.md`, `docs/ai/PROJECT_KERNEL.md`
- Visual evidence loop: `docs/ai/VISUAL_TRUTH_LOOP.md`
- Bounded improvement workflow: `docs/ai/GODLY_WORKFLOW.md`
- Signal flow reference: `docs/ai/SIGNAL_MAP.md`

Default behavior: inspect real files first, identify the bottleneck, choose one bounded fix, preserve working behavior, validate honestly, and report compactly.

## AI Control Plane
Before repo work, read `docs/ai/AI_CONTROL_PLANE.md` and follow the relevant routing/report/validation contract.
