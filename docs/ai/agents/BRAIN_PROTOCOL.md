# BRAIN — PROTOCOL & ADAPTER (v2.1)

## Objective
This file defines how to invoke, route, and interact with the BRAIN system. It serves as the adapter for project-native agents to synchronize their work with the orchestrator.

---

## 1. WHEN TO USE BRAIN
- **Full BRAIN (`docs/ai/agents/BRAIN.md`)**: Use for major system design, high-level strategy, canon restructuring, or complex multi-agent coordination.
- **BRAIN KERNEL (`docs/ai/agents/BRAIN_KERNEL.md`)**: Use for fast-load context, bounded tasks, or maintaining truth during implementation passes.

---

## 2. TASK CLASSIFICATION (The Bounded Move)
BRAIN routes tasks through the standard Taxonomy but adds **Orchestration Layers**:

- **Inspect (SYMBIOTE)**: Read, map, sync repo truth. **Drop context when done.**
- **Spec (BRAIN)**: Plan a change + Blast Radius Analysis + Specialist Selection.
- **Patch (ALFRED/SURGEON)**: Execute surgical code mutation.
- **Audit (CYBORG/AUDITOR)**: Critique and verify against Layer 1.
- **Evolve (BRAIN)**: High-mutation system upgrades or canon promotion.

---

## 3. ROUTING TABLE
BRAIN routes work based on task nature:

| Task Type | Lead Agent | Supporting Agent(s) |
| :--- | :--- | :--- |
| **Lore / Narrative** | Lore Brain | Gemini (Consistency) |
| **System Design / Spec** | Claude | Architect / Scout |
| **Implementation / Fixes** | Codex / Surgeon | Auditor (Validation) |
| **Repo Scans / Audits** | Gemini | Scout / Auditor |
| **Text / Naming Help** | Copilot | Lore Brain |

---

## 4. THE HANDOFF FORMAT
When BRAIN generates a handoff for a specialist agent, it must follow this format to ensure the agent receives compressed, high-power context.

```md
### Handoff to [AGENT_NAME]
- **Target File(s)**: [PATHS] (Only load these files)
- **Working Truth**: [CONTEXT_LIMIT] (e.g., "The player has 3 lanes, 'Combat_HUD' is the only valid UI during song")
- **Bounded Goal**: [TASK_DESCRIPTION] (e.g., "Implement Trait Extraction UI in the post-song screen")
- **Locked Core Constraint**: [IDENTITY_LOCK] (e.g., "Must NOT pause active combat")
- **Validation Requirement**: [SPECIFIC_CHECK] (e.g., "Verify GDScript 2.0 static typing on the emitted signal")
```

---

## 5. CONTEXT WINDOW MANAGEMENT (Vibe-Coding Rules)
To prevent agents from becoming bloated or confused:
- **Assumption-Bust First**: Never assume a node or script exists based on old memory. Read the file (Layer 2) first.
- **Drop the Dead Weight**: If SYMBIOTE inspects 5 files but only 1 needs patching, drop the other 4 from the working context before handing off to ALFRED.
- **Drift Harvesting**: If you encounter strange behavior that fits the "Surreal System-Horror" vibe, don't just delete it. Ask BRAIN if it should be promoted to Layer 3 (Evolving Spine) as a feature.

---

## 6. CANON CHANGE CLASSIFICATION
When proposing changes to the **5-Layer Canon**, they must be categorized:

- **Type A (Structural)**: Promotes an idea to Layer 1 (Locked Core). Requires high-level Spec.
- **Type B (Functional)**: Updates Layer 2 (Live Build Truth). Requires implementation evidence.
- **Type C (Evolutive)**: Mutates Layer 3 (Evolving Spine). BRAIN's primary domain.
- **Type D (Strategic)**: Moves ideas into Layer 4/5 (Scope). Strategic deferral.

---

## 7. VALIDATION SHAPING
BRAIN requires specialists to use the **Auditor's Report (V2)** for all final outputs to ensure the "Shadow Pair" loop is honored.

*See `AGENTS.md` for the standard report template.*