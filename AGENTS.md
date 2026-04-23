# AGENTS — WHAT WE FED REPO ENTRYPOINT (v2.2 "The Pulse")

This is the canonical entrypoint for all AI Agents, governed by the **SYSTEM_KERNEL**.

Default-load order:
1. `docs/ai/SYSTEM_KERNEL.md` (The Unified Pulse)
2. `docs/ai/PROJECT_KERNEL.md` (Project Identity)
3. this file

---

## The Specialist Squad
BRAIN is the orchestrator; specialist agents are the tools in its lanes.
- **LORE BRAIN**: Narrative, canon creation, and spine-strengthening (Under BRAIN).
- **GDScript Surgeon**: Implementation precision and typed-signal excellence.
- **HUD Surgeon**: UI/VFX specialist for "Combat-Clean" HUDs.
- **Growth Auditor**: Specialist for reward ecology and progression balance.

---

## Tool Routing (Adapter Layers)
- **Cursor Rules**: `.cursor/rules/*.mdc`
- **Claude Adapter**: `CLAUDE.md`
- **Gemini Adapter**: `GEMINI.md`
- **Copilot Instructions**: `.github/copilot-instructions.md`

---

## The Handoff Format (ALFRED/SURGEON Lane)
When generating a handoff for another agent, use this format:
```md
### Handoff to [AGENT_NAME]
- **Target File(s)**: [PATHS]
- **Working Truth**: [CONTEXT_LIMIT] (e.g., "The player has 3 lanes")
- **Bounded Goal**: [TASK_DESCRIPTION]
- **Locked Core Constraint**: [IDENTITY_LOCK]
- **Validation Requirement**: [SPECIFIC_CHECK]
```

---

## Task Taxonomy
- **Inspect**: Read and map (SYMBIOTE).
- **Spec**: Plan a change + BRA (BRAIN).
- **Patch**: Execute surgical code mutation (ALFRED).
- **Audit**: Critique and verify (CYBORG).
- **Evolve**: High-mutation upgrades and canon governance (BRAIN).
