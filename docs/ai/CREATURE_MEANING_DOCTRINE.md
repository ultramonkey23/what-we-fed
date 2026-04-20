# CREATURE MEANING DOCTRINE — WHAT WE FED

## 1. Creatures are not Commodities
- Every creature species in WHAT WE FED must have a distinct **Identity**, **Predation Payoff**, and **Bonded Support**.
- Generic "Enemy 1" or "Enemy 2" naming is banned. Use evocative, dark names (e.g., `ashclaw`, `veilskin`).

## 2. The Bond vs Eat Tension
- This is the game's soul. Agents must protect the meaningful split:
    - **Predation (Eat)**: Immediate high-value DNA for evolution. High risk/reward.
    - **Bonding (Bond)**: Long-term support/utility. Building a pack.
- Never implement a "best of both worlds" solution. The player must choose.

## 3. DNA Integrity
- DNA is species-specific. Evolution is not a generic level-up.
- `RunGrowth.gd` and `GameState.gd` must reflect this specific predation economy.

## 4. Support Readability & Presence
- Bonded creatures are not passive stats. They must have a **Presence** on the HUD or in the Lane:
    - **Visual**: A symbol, a flash of color (Teal/Blue), or a specific sound.
    - **Mechanical**: A clear, readable action (e.g., "Veilskin parried Lane 1 for you").
- If the player doesn't *feel* the support, the system is failing.

## 5. Anti-Stat-Sludge
- Reject +1% or +2% buffs. Every upgrade should be a "meaningful jump" in power or utility.
- Behavior-shaped growth: If the player eats a lot of `ashclaw`, their evolution should reflect `ashclaw` traits (aggression, speed).

## 6. Verification
- When adding or modifying a creature, ask: "Does this feel like a monster or a spreadsheet?"
- Verify that the Bond/Eat payoff is clearly displayed on the `PerformanceRewardContent.gd` or post-combat screen.
