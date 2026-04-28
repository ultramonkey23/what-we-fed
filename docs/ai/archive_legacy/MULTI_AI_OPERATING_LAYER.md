# WHAT WE FED - Multi-AI Operating Layer

This is the compact shared contract for Claude, Codex, Gemini, Cursor, Copilot, Cline, and future repo agents. It exists to keep the whole AI system powerful without making every adapter load the same long prompt.

## Purpose
- Keep all agents grounded in the same project truth.
- Preserve each tool's strongest lane instead of flattening them into one generic assistant.
- Route repeated procedures into skills, role packs, hooks, or docs.
- Make validation expectations portable across AI tools.

## Critique of the Current AI Layer
- Strength: the repo has strong soul, high agent specificity, and clear authority doctrine.
- Strength: Claude now has a native layer with memory, scoped rules, subagents, skills, and hooks.
- Weakness: other adapters can drift because they reference the same doctrine unevenly.
- Weakness: long kernel-style docs are sometimes treated as always-loaded truth when they should be loaded on demand.
- Weakness: old lane names and current specialist names can blur unless adapters explicitly map them.
- Upgrade rule: improve routing and validation cohesion without weakening creator authority, repo truth, or the weird predatory identity of the game.

## Authority
1. Creator authority.
2. Current repo truth.
3. Current live-build truth.
4. Evolving spine.
5. Older canon/source docs.
6. Dream scope.

Canon guides building, but it does not fight stronger repo truth.

## Locked Core
Always preserve timing truth, lane/readability truth, readable support, combat honesty, DNA as species-specific predation economy, meaningful bond vs eat, realtime song-run flow, behavior-shaped growth, and "start weak, become feared."

Reject generic survivor, generic collector, generic roguelite soup, rhythm gimmick, spreadsheet sludge, and pretty unreadable action clutter.

## Agent Lanes
- **BRAIN decides**: strategy, authority conflicts, best next move, scope boundaries.
- **SYMBIOTE connects**: repo scans, dependency maps, stale-doc reconciliation, context compression.
- **CYBORG upgrades**: validation, hardening, extraction, workflow infrastructure, behavior-preserving restructuring.
- **ALFRED simplifies**: bounded implementation, GDScript surgery, user-enabling handoffs.
- **INSPECTOR sees**: screenshots/captures, HUD/VFX readability, visual evidence receipts.

Legacy lane names map into these lanes:
- Architect -> BRAIN.
- Scout -> SYMBIOTE.
- Auditor -> CYBORG.
- Surgeon/GDScript Surgeon/HUD Surgeon/Shader Surgeon -> ALFRED under a specialty.
- Lens/Visual Inspector -> INSPECTOR.

## Tool Strengths
- Claude Code: orchestration, scoped memory, subagents, skills, hooks, code edits.
- Codex: pragmatic implementation, repo hardening, tests/validation, terminal work.
- Gemini: broad repo scan, contradiction sweep, large-context synthesis, scout/auditor support.
- Cursor/Copilot: inline implementation assistance; must follow repo truth and avoid speculative rewrites.
- Cline: task board/workflow support when present; should consume the same authority and validation contract.

## Routing Rule
Every non-trivial task should pick one lead lane before acting:
- Strategy/spec -> BRAIN.
- Research/map/conflict -> SYMBIOTE.
- Infrastructure/validation/extraction -> CYBORG.
- Patch/fix/implementation -> ALFRED.
- Visual/readability judgment -> INSPECTOR, then ALFRED if a patch is needed.

If the user's prompt names a lane, obey it unless it conflicts with creator authority or repo truth.

## Context Loading Rule
Start short:
- `CLAUDE.md` or tool-specific adapter.
- `AGENTS.md`.
- `PROJECT_SETUP_AND_VALIDATION.md`.
- `REPO_SYSTEM_MAP.md`.

Load deep docs only when the task needs them:
- `docs/ai/SYSTEM_KERNEL.md` for full governance.
- `docs/ai/PROJECT_KERNEL.md` for identity.
- `docs/ai/CONTEXT_EXPANSION_MAP.md` for file discovery.
- `docs/ai/VISUAL_TRUTH_LOOP.md` for visual evidence.
- `.claude/skills/*/SKILL.md` for repeatable Claude procedures.

## Validation Rule
Validation must match the claim:
- Script/runtime boot claim: `smoke_project.bat`.
- Data/content claim: `validate_data.bat`.
- Import/asset/handoff claim: `validate_project.bat`.
- Combat-state claim: `debug_harness.bat`.
- Feel/readability/input claim: `run_project.bat` or screenshot/capture evidence.

Never claim validation that was not performed. Static-only is acceptable when named honestly.

## Upgrade Rule
When improving the AI system:
1. Critique the existing layer first.
2. Preserve what is powerful.
3. Remove duplicated prompt burden.
4. Add routing/procedure/hook infrastructure only when it removes real friction.
5. Leave gameplay and lore untouched unless explicitly requested.
