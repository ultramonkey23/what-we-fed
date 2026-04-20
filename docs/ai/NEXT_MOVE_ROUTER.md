# NEXT MOVE ROUTER — WHAT WE FED

Choosing the "One Best Next Move" is critical to avoid drift and vanity cleanup.

## 1. Task Classification
- **Level 1 — Blocker**: Immediate crash/hang. Use `BUGFIX_WORKFLOW.md`.
- **Level 2 — Identity Leak**: Timing is floaty, lanes are cluttered, or "mushy" feel.
- **Level 3 — Feature/Growth**: Implementing requested mechanics.
- **Level 4 — Content**: Adding new creatures/songs to data.
- **Level 5 — Robustness**: (Only if Level 1-3 are stable).

## 2. Decision Logic
- **Always solve lower levels first.** You cannot polish a feature that is crashing.
- **Reject "Just Because" Refactors.** If it works and is readable, leave it.
- **Identify the "Weakest Link"**: If the game is stable, what is the *single* most confusing or generic element? That is your Level 2/3 target.

## 3. The One Best Move Rule
1. Pick **exactly one** bottleneck.
2. State **why now**.
3. State **what should wait**.
4. Confirm with the user before starting a Level 3+ move.

## 4. Anti-Drift Check
- Does this move protect **Lane Truth**?
- Does this move protect **Timing Truth**?
- Does this move protect **Bond vs Eat**?

**Example Router Output**:
> Bottleneck: Lane 0 projectiles are too dark.
> Move: Increase luminance of Lane 0 sprite.
> Wait: Adding new enemy types or cleaning up Projectile.gd initialization.
