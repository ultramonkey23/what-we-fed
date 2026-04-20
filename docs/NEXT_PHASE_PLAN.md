# NEXT PHASE PLAN

## Immediate goal
Use the current What We Fed prototype as the implementation base and improve it safely.

## Current Progress (Completed)
- **Timing Truth**: Visual rings now mathematically align with combat logic.
- **Data-Driven UI**: Reward body text, effect descriptions, and tier identities are now centralized in `PresentationTextContent.gd` and `UIStyle.gd`.
- **Visual Polish**: Added background beat-blooms, chromatic impact jitters, and organic UI scale pulses.
- **Stability**: Resolved circular dependencies and parse errors in core combat scripts.

## Right now
Focus on:
- identifying safe data extraction targets (Encounter/Enemy data)
- improving readability of hardcoded encounter content
- centralizing repeated feel/timing values (slow-motion, hitstop)
- adding clearer comments around lane/timing rules
- keeping the style direction aligned with dark-cool ascendant creature power fantasy

## Not yet
Do not do these yet unless explicitly requested:
- rewrite architecture
- convert the whole game into the full flagship concept
- add giant systems all at once
- merge in every survivor-like idea immediately
- rebuild the prototype from scratch
- soften the game into harmless anime-clean gloss or generic superhero tone

## Good next tasks
- move creature and encounter data out of `CombatScene.gd`
- centralize combat feel constants (slow-motion, camera shake defaults)
- improve Quig commentary logic and data-driven triggers

## Future merge direction
Later, after the current prototype is better understood and stabilized, begin merging in:
- stronger creature identity
- world/music/ecology systems
- boss performance states
- Quig commentary
- mutation and cadence-based authorship
- influence-vector alignment (Solo Leveling, Digimon, My Hero Academia, Ben 10) as direction cues, not copy templates
