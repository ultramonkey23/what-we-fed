# What We Fed - Stat System Map

## Player Stats
- **Defined in:** autoloads/GameState.gd, systems/RunGrowth.gd, systems/RunStats.gd, systems/CombatMeter.gd
- **Stats:**
  - HP (player_hp, player_max_hp)
  - Damage (player_base_damage, attack_damage)
  - Defense (player_defense)
  - Stamina (CombatMeter.gd)
  - Bond Level (roster, RunGrowth.gd)
  - DNA (dna_by_species)
  - Tendency (RunGrowth.gd)
  - Mutations (RunGrowth.gd)
- **Modification:**
  - Level-up (RunGrowth.gd)
  - Mutations (RunGrowth.gd)
  - Region effects (GameState.gd)
  - Rewards (RunGrowth.gd, PerformanceRewardDirector.gd)

## Enemy Stats
- **Defined in:** data/CombatContent.gd, region/encounter data
- **Stats:**
  - HP
  - Damage
  - Defense
  - Special (affinity, status effects)
- **Modification:**
  - Region/encounter scaling (CombatContent.gd, region data)
  - Mutations (future/partial)

## Stat Flows
- **Initialization:**
  - Player: GameState.gd (reset_run_state), RunGrowth.gd (_on_run_started)
  - Enemy: CombatContent.gd (get_creature, get_enemy)
- **Modification:**
  - Level-up: RunGrowth.gd (_grant_exp, _apply_real_time_growth_pulse)
  - Mutation: RunGrowth.gd (mutations array)
  - Region: GameState.gd (active_region modifiers)
  - Rewards: RunGrowth.gd, PerformanceRewardDirector.gd
- **Usage:**
  - Combat: PlayerCombat.gd, LaneManager.gd, CombatMeter.gd
  - UI: CombatHUDPresenter.gd, RunGrowth.gd (signals)

## Signals/Events
- EventBus: run_growth_changed, support_charge_changed, dna_routing_changed, player_healed, etc.

## Next Steps
- Centralize all base stat definitions
- Standardize stat modification methods
- Review enemy scaling logic
- Validate after each change
