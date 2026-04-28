# AI System Upgrade Review

This review critiques the Claude enablement pass and records the follow-up upgrade for the rest of the AI system.

## Critique
- The Claude pass was structurally correct: concise `CLAUDE.md`, scoped memories, project subagents, skills, and advisory hooks.
- It was too Claude-centered for a repo that already runs a multi-agent ecosystem.
- It did not give Gemini, Cursor, Copilot, Codex, and Cline a single shared contract to reduce adapter drift.
- It added strong Claude procedures, but other tools still had to infer lane names and validation expectations from older docs.
- It risked creating two operating centers: old `docs/ai/*` doctrine and new `.claude/*` infrastructure.

## Upgrade
- Added `docs/ai/MULTI_AI_OPERATING_LAYER.md` as the compact cross-AI contract.
- Updated `AGENTS.md` and `docs/ai/TERMINAL_AI_BOOTSTRAP.md` so terminal agents start with the shared layer.
- Updated `GEMINI.md`, `.github/copilot-instructions.md`, `.codex/config.toml`, and Cursor core/routing rules to point at the same contract.
- Added `.clinerules` for Cline with authority, locked-core, routing, and validation rules.
- Kept deep doctrine out of adapters and preserved tool-specific strengths.

## Preserved Power
- BRAIN remains the strategic authority lane.
- SYMBIOTE remains the repo-truth and interconnection lane.
- CYBORG remains the hardening/extraction/validation lane.
- ALFRED remains the surgical implementation lane.
- INSPECTOR remains the evidence-based visual truth lane.

## New Rule
Every future AI adapter should be a thin pointer into the shared contract plus a tool-specific strength statement. Do not duplicate the full canon into every adapter.
