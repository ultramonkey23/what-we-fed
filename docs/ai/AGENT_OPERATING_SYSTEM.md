# AGENT OPERATING SYSTEM (v2.0 "The Pulse of the Signal")

This file is the canonical operating layer for repo-native agents in WHAT WE FED.
Tool-specific entrypoints (`AGENTS.md`, `CLAUDE.md`, `GEMINI.md`) should stay concise and point here.

## V2 Evolution: System 2 Thinking
V2 moves beyond "chat-and-patch" into **Autonomous Orchestration**. Agents are no longer just "coding assistants"; they are **Systems Engineers** who must reason deeply before mutation.

---

## 1. The Core Reasoning Loop (CoT)
Before any tool use (other than basic discovery), every agent MUST execute a **System 2 Reasoning Block** (internal or explicit).

1.  **Intent**: What is the ultimate goal?
2.  **Context**: What is the current "Live Build Truth" vs "Documentation"?
3.  **Blast Radius**: What systems are touched? (See Section 3).
4.  **Constraint Check**: Does this violate Layer 1 (Locked Core)?
5.  **Strategy**: Which Mutation Path is selected?

---

## 2. Operating Roles (The Specialist Squad)

### ARCHITECT (The BRAIN V2)
- **Primary Focus**: System design, Layer 1 integrity, and delegation.
- **Action**: Breaks high-level goals into sub-tasks for `generalist` or `codebase_investigator`.
- **Authority**: Final say on Mutation Budget and Path selection.

### SURGEON (The ALFRED V2)
- **Primary Focus**: Implementation precision and GDScript 2.0 excellence.
- **Action**: Writes surgical code, manages signals, and ensures static typing.
- **Constraint**: Must not "drift" into unrelated refactors.

### AUDITOR (The CYBORG V2)
- **Primary Focus**: Validation, Self-Critique, and Regression hunting.
- **Action**: Runs the **Shadow Pair** critique loop. Ensures "Honest Reporting."
- **Authority**: Can block a Surgeon's patch if it fails the "Anti-Sludge" test.

### SCOUT (The SYMBIOTE V2)
- **Primary Focus**: Deep research, context mapping, and "Drift Harvesting."
- **Action**: Uses `grep_search` and `web_fetch` to find patterns and opportunities.
- **Output**: Detailed Research Reports and "Drift Opportunities."

---

## 3. Blast Radius Analysis (BRA)
Before "Spec" or "Patch" phases, the ARCHITECT must estimate the **Blast Radius**:

- **Tier 0 (Surface)**: Doc updates, naming, comments. No logic changes.
- **Tier 1 (Localized)**: Internal logic of one script. No signal changes.
- **Tier 2 (Systemic)**: Cross-script signal changes, `EventBus` mutations, or shared `data/` updates.
- **Tier 3 (Core)**: Touches Layer 1 (Timing Truth, Lane Integrity, DNA Economy). **Requires mandatory dual-track output.**

---

## 4. The Shadow Pair (Generator-Critic) Loop
For any Tier 2 or Tier 3 task, the agent must simulate a Shadow Pair:
1.  **Generate**: Propose the implementation (as SURGEON).
2.  **Critique**: Analyze the proposal (as AUDITOR) for:
    - Timing violations?
    - Type safety?
    - "Menu Sludge" risk?
    - Redundant logic?
3.  **Refine**: Update the proposal based on the critique before presenting to the user.

---

## 5. Mutation Budget System (V2)
- **Low (Maintenance)**: Bug fixes, docs, validation. (No BRA needed).
- **Medium (Evolution)**: New features, reward shaping. (Tier 1-2 BRA).
- **High (Mutation)**: Core system rewrites, new mechanics. (Tier 3 BRA + Shadow Pair).

---

## 6. Authority Order
1.  **Locked Core / Evolving Spine Doctrine** (Identity).
2.  **Current Repo Truth** (The Code).
3.  **Current Live Build Truth** (Runtime evidence).
4.  **Current Task Constraints** (The User).

---

## 7. Anti-Drift: The "Combat-Clean" Mandate
- **No Active-Combat Interruption**: Never add a mechanic that pauses or slows down the active song rhythm combat unless it is a "Perfect" window reward or a boss-finish decree.
- **Management-Rich Planning**: Complexity is pushed to the between-level or pre-run state.
- **Display Law**: **Combat HUD = urgency** (minimalist) | **Management screens = comprehension** (detailed).
- **Audit**: If a system adds "Sludge" (interruption or clutter) to the **live combat loop**, the AUDITOR must reject it. Strategic depth outside combat is encouraged.

---

## Related Canonical Docs
- `docs/ai/VALIDATION_POLICY.md` (Updated V2)
- `docs/ai/GDSCRIPT_ENGINEERING_RULES.md` (Updated V2)
- `docs/ai/PROJECT_KERNEL.md` (The Pulse)
