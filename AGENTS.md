# AGENTS — WHAT WE FED REPO ENTRYPOINT (v2.3 "The Pulse")

This is the canonical entrypoint for all AI Agents, governed by **Creator Authority**.

Authority Order:
1. **User / Creator Intent**: Highest authority.
2. **Current Repo Truth**: Implementation reality (Layer 2).
3. **Current Live-Build Truth**: What is actually working now.
4. **Evolving Spine**: Current intended direction and accepted design movement.
5. **Older Canon / Source Docs**: Memory and guidance only. Useful, but never allowed to outrank the creator.

Terminal Bootstrap:
- Terminal-based AI sessions should load `docs/ai/TERMINAL_AI_BOOTSTRAP.md` first when the tool supports repo instructions.

Core Read Order:
1. `docs/ai/SYSTEM_KERNEL.md` (The Unified Pulse)
2. `docs/ai/PROJECT_KERNEL.md` (Project Identity)
3. `AGENTS.md` (Entrypoint / routing)

Terminal AI Rule:
- Any terminal-based AI session in this repo should load `docs/ai/TERMINAL_AI_BOOTSTRAP.md` first, then use the core read order above.
- If a tool can only load one file automatically, point it at `AGENTS.md`; this file delegates to the bootstrap and kernel.
- If a task involves visuals, screenshots, frame captures, HUD readability, projectile/support clarity, or boss spectacle, route through INSPECTOR and `docs/ai/VISUAL_TRUTH_LOOP.md` before patching.

---

## The Specialist Squad
BRAIN is the orchestrator; specialist agents are the tools in its lanes.
- **Architect (BRAIN)**: System design, strategy, and Best-Next-Move selector.
- **Auditor (CYBORG)**: Verification, self-upgrading, and agent-extraction specialist.
- **Scout (SYMBIOTE)**: Interconnectivity, deep repo mapping, and context compression.
- **Surgeon (ALFRED)**: Usability, smooth handoffs, and surgical GDScript mutation.
- **Inspector (Visuals)**: Visual truth, readability audits, and aesthetic alignment.

---

## Tool Routing (Adapter Layers)
- **Cursor Rules**: `.cursor/rules/*.mdc`
- **Claude Adapter**: `CLAUDE.md`
- **Gemini Adapter**: `GEMINI.md`
- **Copilot Instructions**: `.github/copilot-instructions.md`
- **Remote Commands**: `docs/ai/REMOTE_COMMAND_SYSTEM.md`

---

## The Handoff Format (Universal Lane)
When generating a handoff for another agent, use this format:
```md
### Handoff to [AGENT_NAME]
- **Target File(s)**: [PATHS]
- **Working Truth**: [CONTEXT_LIMIT] (e.g., "The player has 3 lanes")
- **Bounded Goal**: [TASK_DESCRIPTION]
- **Creator Intent**: [SPECIFIC_GOAL]
- **Technical Risk / Constraint**: [RISK_OR_GUIDANCE]
- **Validation Requirement**: [SPECIFIC_CHECK]
```

### Inspector Visual Truth Addendum
When handing off to INSPECTOR, include this block. If a value is unavailable, write `unknown` rather than guessing.
```md
#### Visual Evidence Packet
- **Evidence Path(s)**: [PNG/JPG/WEBP/MP4 paths]
- **Moment ID**: [e.g., player_took_damage | timed_attack_perfect | bonded_support_triggered | ultimate_fired]
- **Scene**: [current scene path/name]
- **Viewport**: [width x height]
- **Camera Zoom**: [x,y]
- **Camera Offset**: [x,y]
- **Combat Tier**: [stirring | hunting | rampage | apex | sovereign | unknown]
- **Resonance Tier**: [song profile tier/id or unknown]
- **Song Context**: [song_id, section_id, beat_index, beat_quality, intensity]
- **Lane Context**: [active lane, source/threat lane, lane y positions if known]
- **Support Context**: [active bonded species, support charge, support effect id if relevant]
- **Active Buffs/Mutations**: [ids or count]
- **Expected Visual Contract**: [specific doctrine check: lane floor visible, support blue/teal, enemy hot, shell not slab]
```

---

## Task Taxonomy
- **Inspect**: Read and map (SYMBIOTE).
- **Spec**: Plan a change + BRA (BRAIN).
- **Patch**: Execute surgical code mutation (ALFRED).
- **Audit**: Critique and verify (CYBORG).
- **Evolve**: High-mutation upgrades and canon governance (BRAIN).
