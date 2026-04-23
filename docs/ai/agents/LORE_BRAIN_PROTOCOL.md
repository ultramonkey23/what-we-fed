# BRAIN LOBE: LORE BRAIN — PROTOCOL (v2.1 Sovereignty)

## Objective
To provide a reusable narrative authority lobe connected to the **BRAIN Orchestrator**.

---

## Consumer Adapters (Lobes & Agents)

### 1. Claude (Story Synthesis & Myth Architecture)
- **Call Lore Brain for**: Faction evolution, mythology architecture, deeper story synthesis, tone correction.
- **Workflow**: Lore Brain Spec -> BRAIN Spec -> Claude Synthesis -> CYBORG Audit.

### 2. Gemini (Repo/Source Audit & Contradiction)
- **Call Lore Brain for**: Broad canon alignment, comparing multiple lore sources, finding contradictions across docs.
- **Workflow**: Lore Brain Kernel -> BRAIN Audit -> Gemini Reconciliation.

### 3. Codex (Implementation & Game-Logic Integration)
- **Call Lore Brain for**: Implementation-facing descriptions, UI text integration, journal/logbook support, dialogue wiring.
- **Workflow**: Lore Brain Kernel -> BRAIN Handoff -> ALFRED (Surgeon) Execution.

### 4. Copilot (Naming Consistency & Naming Tone)
- **Call Lore Brain for**: Item/reward/faction naming consistency, player-facing text tone alignment.
- **Workflow**: Lore Brain Kernel -> Copilot Suggestion (Guided by BRAIN).

---

## Routing Law
- **BRAIN KERNEL** (`docs/ai/agents/BRAIN_KERNEL.md`) is the primary orchestrator entrypoint.
- Use **LORE BRAIN KERNEL** (`LORE_BRAIN_KERNEL.md`) for fast-load naming/tone tasks.
- Use **LORE BRAIN FULL SPEC** (`LORE_BRAIN.md`) for substantial world-building or system-wide narrative updates.

---

## BRAIN Handoff Contract
Every Lore Brain proposal ends with a ready-to-paste instruction for the target lobe/agent:
- **Example**: "Handoff to ALFRED: Implement the 'Ashclaw' description in `CreatureTraitContent.gd` following the v2.1 predatory canon."
