# NEXT PHASE PLAN

## Immediate goal
Use the current What We Fed prototype as the implementation base and improve it safely.

**Run shape (design target):** **9** regular levels (each **under ~2 min** of authored song slice) **+ 1** boss (full song); **menus between** regular levels for reward choice, then inventory/resource management, then the next song.

## Current Progress (Completed)
- **Timing Truth**: Visual rings now mathematically align with combat logic.
- **Data-Driven UI**: Reward body text, effect descriptions, and tier identities are now centralized in `PresentationTextContent.gd` and `UIStyle.gd`.
- **Visual Polish**: Added background beat-blooms, chromatic impact jitters, and organic UI scale pulses.
- **Stability**: Resolved circular dependencies and parse errors in core combat scripts.
- **Creature Breadth Pass v1**: Multiple species now have distinct eat effects, bond passives, support roles, encounter profiles, affinities, and reward-pool placement.
- **Performance Reward Pack v1**: Performance reward content and director logic now include score/kill pressure, active affinity, bond/eat history, tendency alignment, stored reward flow, and between-level choice context.

## Potential quick-start (v1)
When touching Potential, treat it as a **ceiling/unlock/escalation** system, not flat combat power.

- Read first: `docs/POTENTIAL_SYSTEM_V1.md`
- Keep tendency as live combat-growth (`systems/RunGrowth.gd`)
- Creature/world authored ceilings live in:
  - `data/CombatContent.gd` (`potential_max_grade` on species)
  - `data/RouteContent.gd` (`potential_max_grade` on regions)
- Runtime flow:
  - `systems/PotentialGate.gd` resolves layered ceiling
  - `scenes/combat/CombatScene.gd` injects `grade_ceiling_id` into `encounter_options`
  - `systems/EncounterIdentityRuntime.gd` clamps enemy `grade` down during song phase scaling
- Keep UI minimal: Potential readout belongs on collector surfaces first (e.g. `scenes/ui/LairScene.gd`), not combat HUD
- Validate with `smoke_project.bat`, then `run_project.bat` spot-check for default parity and one low-potential cap scenario

## Right now
Focus on:
- proving upgrade depth from the expanded creature roster
- making performance rewards read as earned by score, kills, clean play, support usage, and bond/eat history
- balancing affinity-biased reward offers so different bonded creatures imply different build paths
- improving between-level reward comprehension without adding active-combat menu sludge
- keeping the style direction aligned with dark-cool ascendant creature power fantasy

## Canon-evolution implementation impact map
When planning near-term work, keep these impact areas explicit:
- reward flow orchestration (kill/performance/reward transitions)
- UI/HUD assumption split (combat urgency vs management comprehension)
- inventory/equipment and between-level state flow
- loot/artifact/collar schemas and ownership boundaries
- support equipment bindings (collars affect support behavior, not generic player stats)
- tempo-state logic / time scaling hooks (puncture/suspension/decree)
- creature-grade schema and reward weighting
- region encounter identity logic and pressure ecosystems
- boss threshold/state machines as battlefield law shifts
- world-state consequence hooks and kaiju-line inputs (kept scoped as later/layered rollout)

## Not yet
Do not do these yet unless explicitly requested:
- rewrite architecture
- convert the whole game into the full flagship concept
- add giant systems all at once
- merge in every survivor-like idea immediately
- rebuild the prototype from scratch
- soften the game into harmless anime-clean gloss or generic superhero tone
- pull ranch into near-term priority before reward ecology and support identity are ready

## Good next tasks
- tune and audit the current performance reward pack against real combat score/kills/clean-play outcomes
- make bond-level scaling matter for support value without turning Bond Rank into routine stat drip
- improve reward-card/readout clarity for why each offer appeared
- verify expanded creature support readability under pressure with visual evidence
- keep extracting stale hardcoded combat content only when it directly improves readability or reward/combat payoff

## Future merge direction
Later, after the current prototype is better understood and stabilized, begin merging in:
- stronger creature identity
- world/music/ecology systems
- boss performance states
- Quig commentary
- mutation and cadence-based authorship
- influence-vector alignment (Solo Leveling, Digimon, My Hero Academia, Ben 10) as direction cues, not copy templates
