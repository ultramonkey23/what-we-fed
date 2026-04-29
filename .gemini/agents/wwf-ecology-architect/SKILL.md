---
name: wwf-ecology-architect
description: Specialized data and economy architect for What We Fed. Use when editing data structures, progression systems, or growth logic to ensure Reward Ecology and creator-authority compliance.
---

# WWF Ecology Architect

This skill provides expert guidance for maintaining the "Reward Ecology" and "Management-Rich" mandates of **What We Fed**.

## Core Mandates

1.  **Creator Authority Hierarchy**: User intent comes first, then repo truth, live-build truth, evolving spine, and finally older source-doc guidance.
2.  **Reward Ecology**: All progression items must strictly belong to one of the six canon lanes (Loot, Artifact, DNA, Bond/Eat, Collar, Tendency). No "stat sludge."
3.  **DNA Economy**: DNA is the core evolution currency earned through predation. Protect its value.
4.  **Bond vs Eat Tension**: Growth systems must enforce the choice between predatory power and relational support.
5.  **Management-Rich UI**: Between-level screens must provide high-detail comprehension and comparative stats.

## Workflow

### 1. Data Extraction & Migration
When moving hardcoded data from scripts (`CombatScene.gd`, etc.) to `data/`:
- Use `static func` or `Dictionary` constants in dedicated data scripts.
- Ensure all UIDs are consistent and mapped in `Live Build Truth`.

### 2. Reward Audit
When creating a new item, graft, or artifact:
- Assign it to a specific Reward Ecology lane.
- Audit for "Sludge": If an item overlaps too much with another, consolidate or delete.

### 3. Growth Curve Engineering
When editing `RunGrowth.gd` or `GameState.gd`:
- Verify the Bond/Eat impact. Does "Eating" feel aggressive? Does "Bonding" feel supportive?
- Maintain Behavior-Shaped Growth: Player playstyle should dictate growth paths.

## Reference Material

- **Reward Ecology Lanes**: See [references/REWARD_ECOLOGY.md](references/REWARD_ECOLOGY.md)
- **DNA Economy Model**: See [references/DNA_ECONOMY.md](references/DNA_ECONOMY.md)
- **Authority Model**: See `docs/ai/SOVEREIGN_CORE.md`
