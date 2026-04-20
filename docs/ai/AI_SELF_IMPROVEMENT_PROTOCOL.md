# AI Self-Improvement & Upgrade Protocol

This protocol defines how AI agents (Claude, Codex, Gemini) should evolve their own rules and the game's architecture as WHAT WE FED scales.

## 1. Meta-Correction Protocol
- **Trigger:** An AI agent makes a mistake that leads to a bug, a broken scene, or a violation of the "Locked Core."
- **Action:** The agent **must** analyze the root cause and immediately update the relevant `docs/ai/` file.
- **Content:** Add an "Anti-Pattern" section or a specific rule addressing the failure.
- **Goal:** Every mistake should only ever happen once in the repository's history.

## 2. Knowledge Graduation Protocol
- **Trigger:** A new successful pattern is implemented (e.g., a specific way to handle boss transitions or UI tweens).
- **Action:** If the pattern is used twice, extract the rules for it.
- **Location:** Create or update a specific `.md` file in `docs/ai/` (e.g., `docs/ai/UI_ANIMATION_STANDARDS.md`).
- **Goal:** Move specific implementation knowledge from "ephemeral chat context" to "permanent repo truth."

## 3. System Upgrade Protocol (Architectural Graduation)
- **The Rule of Three:** 
    - 1-2 instances: Surgical patches and hardcoding are acceptable to maintain momentum.
    - 3+ instances: Architectural graduation is **mandatory**. Extract the logic into a data-driven system or a dedicated helper.
- **Procedure:**
    1. **Plan:** Propose the graduation (e.g., "Moving Boss 1/2/3 patterns into a CSV/GDScript data table").
    2. **Approve:** Wait for user confirmation.
    3. **Execute:** Implement the data-driven layer and remove the hardcoded variants.
- **Target Systems:** Boss patterns, Creature stats, Region pressure rules, and Support roles.

## 4. Maintenance of the AI Ruleset
- **Bi-Weekly Review:** Every 2 weeks, an agent should scan the `docs/ai/` folder and consolidate rules that have become redundant or conflicting.
- **Non-Restriction Rule:** Protocols must remain practical and additive. If a rule stops helping agents write better code, remove or simplify it.
- **Locked Core Priority:** No AI-driven "self-improvement" or "upgrade" can ever override the "Locked Core" project identity without explicit user direction.