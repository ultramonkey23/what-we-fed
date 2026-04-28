# CORE SYSTEMS & GROWTH — LOCAL INSTRUCTIONS

## THE AUTHORITY HIERARCHY
All system design must adhere to the project's authority hierarchy:
1. **User / Creator Intent**: Highest authority.
2. **Current Repo Truth (Layer 2)**: Sentient System identity, Deterministic Growth, Creature Classes.
3. **Older Canon / Source Docs (Layer 1)**: DNA economy, Bond vs Eat tension. Useful memory.

## System Philosophy: The Sentient Codex
The player is the **Living Codex**, a cosmic System that extracts traits. Growth is not a choice; it is diegetic evolution.

- **Deterministic Extraction**: Growth is behavior-shaped but outcome-certain. Aggression MUST grant Power. Guard MUST grant Carapace. No RNG stat sludge.
- **Creature Classes**: Permanent Lair Bonds act as the System's "Grafted Classes," granting unique starting stat modifiers (Loot Lane).
- **Meta-Ceiling**: The Codex scales to **Level 10,000**.
- **Management-Rich**: Pre-run screens must show the specific "Extraction Math" for each creature and tendency level.

## Reward Ecology: Lane Separation
1. **Loot / Classes**: Character class modifiers (Lair Bonds).
2. **Artifacts / Relics**: Shape the run.
3. **DNA**: The extraction currency.
4. **Bond / Eat**: Relational compromise vs Pure System Evolution.
5. **Collars**: Support behaviors.
6. **Tendencies**: The primary extraction spine.

## Meta-State Management
- **Persistence**: Only **Potential** and **Luck** survive the run reset.
- **Limit Breakers**: Persistent achievement trackers that raise the Codex evolutionary cap (Base 100).
- **Run Local**: All other stats reset but are modified by the permanent Lair Bonds at start-of-run.

## Implementation Rules
- **Growth Effects**: Add deterministic mappings to `systems/RunGrowth.gd`.
- **Classes**: Define class packages in `data/CombatContent.gd`.
- **Leveling**: Use the linear infinite scaling formula in `ProgressionManager.gd`.

## Validation Checklist (Systems-Specific)
- [ ] Is leveling deterministic (Playstyle -> Predicted Stat)?
- [ ] Does `GameState` correctly apply Class modifiers at run start?
- [ ] Does `Potential` correctly amplify the Class bonuses?
- [ ] Do only `Potential` and `Luck` persist after death?
- [ ] Did you verify with `smoke_project.bat`?
