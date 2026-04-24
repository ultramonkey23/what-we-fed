# BRAIN — PROTOCOL & ADAPTER (v2.3)

## Objective
This file defines how to invoke, route, and interact with the BRAIN system. It serves as the adapter for project-native agents to synchronize their work with the orchestrator.

---

## 1. WHEN TO USE BRAIN
- **Full BRAIN (`docs/ai/agents/BRAIN.md`)**: Major system design, high-level strategy, or complex coordination.
- **SYSTEM KERNEL (`docs/ai/SYSTEM_KERNEL.md`)**: The primary source for all rules and validation.

---

## 2. TASK CLASSIFICATION (The Bounded Move)
BRAIN routes tasks through the standard Taxonomy (refer to `AGENTS.md` for detail):
- **Inspect (SYMBIOTE)**: Read, map, sync repo truth.
- **Spec (BRAIN)**: Plan a change + Blast Radius Analysis + Specialist Selection.
- **Patch (ALFRED/SURGEON)**: Execute surgical code mutation.
- **Audit (CYBORG/AUDITOR)**: Critique and verify against creator intent, repo truth, live-build evidence, and relevant identity guidance.
- **Visual Audit (INSPECTOR/LENS)**: Inspect screenshots, captures, or frame sequences and produce patch-ready visual receipts.
- **Evolve (BRAIN)**: High-mutation system upgrades or spine/source-doc promotion.

---

## 3. ROUTING TABLE
BRAIN routes work based on task nature:

| Task Type | Lead Agent | Supporting Agent(s) |
| :--- | :--- | :--- |
| **Lore / Narrative** | Lore Brain | Gemini (Consistency) |
| **System Design / Spec** | Claude | Architect / Scout |
| **Implementation / Fixes** | Codex / Surgeon | Auditor (Validation) |
| **Repo Scans / Audits** | Gemini | Scout / Auditor |
| **Visual Truth / Readability** | Inspector | Scout (context), Surgeon (patch), Auditor (re-capture validation) |
| **Shader / VFX Patch** | Surgeon / Shader Surgeon | Inspector receipt, Auditor validation |
| **Text / Naming Help** | Copilot | Lore Brain |

---

## 4. THE HANDOFF FORMAT
Refer to `AGENTS.md` for the canonical handoff template.

For visual work, include the Inspector Visual Truth Addendum from `AGENTS.md` and attach the capture seed from `docs/ai/VISUAL_TRUTH_LOOP.md`. Unknown metadata must stay `unknown`; do not invent scene, camera, lane, song, or support facts.

---

## 5. CONTEXT WINDOW MANAGEMENT
- **Assumption-Bust First**: Never assume a node or script exists. Read the file (Layer 2) first.
- **Drop the Dead Weight**: Keep context focused only on the current move.

---

## 6. VALIDATION SHAPING
BRAIN requires specialists to use the **Auditor's Report (v2.2)** for all final outputs.

*See `docs/ai/SYSTEM_KERNEL.md` for the report template.*
