# What We Fed - Stat System Map

## Player Stats
- **Defined in:** systems/state/PlayerState.gd (orchestrated by GameState.gd), systems/growth/ (orchestrated by RunGrowth.gd), systems/CombatMeter.gd
- **Stats:**
  - HP (PlayerState.hp, PlayerState.max_hp)
  - Damage (PlayerState.base_damage, PlayerState.get_attack_damage)
  - Defense (PlayerState.defense)
  - Stamina (CombatMeter.gd)
  - Bond Level (CreatureState.roster, RunGrowth.gd)
  - DNA (CreatureState.dna_by_species)
  - Tendency (TendencyManager.gd)
  - Mutations (RewardState.active_mutations)
- **Modification:**
  - Level-up (RunGrowth.gd / ProgressionManager.gd)
  - Mutations (RunGrowth.gd / RewardState.gd)
  - Region effects (GameState.gd / RunState.gd)
  - Rewards (RunGrowth.gd, PerformanceRewardDirector.gd, RewardState.gd)

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

## Compound Interactions (Sovereign Stats Engine)
Owned by `systems/SovereignDamageCalculator.gd`. Stats compound and interact across combat seams; add new interactions here, not inline in `PlayerCombat.gd`.

| Stat | Interaction | Effect | Seam |
|---|---|---|---|
| `stat_power` (Maw) | Power-on-attack compound | All 5 player attack paths (timed, idle, late, parry-reflect, ultimate) scale with `stat_power / BASE_DAMAGE`. Returns 1.0 at base power. | `_get_maw_multiplier()` |
| `stat_carapace` (Bone) | Chip reduction stack | +1%/point chip reduction (cap 20%) ON TOP of base defense reduction (2%/pt, cap 30%); combined cap 45% via `GameState.COMBINED_DAMAGE_REDUCTION_CAP`. | `get_incoming_damage_after_reduction()` |
| `stat_carapace` (Bone) | Defense → timing forgiveness | +2.5 px parry/attack timing radius per point (cap 22 px). Defense buys breathing room on the beat. | `get_parry_forgiveness_radius_bonus()` |
| `stat_adaptability` (Form) | Form on timed | Multiplies timed attack and ultimate damage; multiplies heal amount. Already lived in code; the calculator is now its named owner. | `get_timed_attack_damage()`, `get_ultimate_damage()`, `PlayerState.heal()` |
| `bond_level` × species | Bond-trait expression | Vessel-cleave adjacent damage scales with species bond level, weighted by `VESSEL_BOND_TRAIT_WEIGHT = 0.65`. Bonded creature passives also scale per-bond-level via `_sum_bond_passive(passive_type)` in `PlayerCombat.gd`. | `get_vessel_trait_multiplier()`, `PlayerCombat._sum_bond_passive()` |
| `stat_swiftness` (Nerve) | Action recovery speed | All `_lock_action` durations multiplied by `1 / stat_swiftness`, clamped 0.40–2.0. Higher swiftness = shorter recovery; floor prevents trivializing timing. | `get_action_recovery_mult()`, `PlayerCombat._lock_action()` |
| `stat_swiftness` (Nerve) | Melee reach / lunge reach | Base melee blade length starts short at 112 px and grows slowly with Nerve, capped at 168 px. Predatory lunge acquisition covers the striker orbit at 2.90x blade length, capped at 360 px, so resumed reward combat can immediately reacquire a target without making the slash giant. | `get_attack_range()`, `get_predatory_lunge_range()` |
| `stat_adaptability` (Form) | Simultaneous enemy contact cap | Base attacks lock and damage 1 enemy. Extra targets unlock slowly at +0.75 Form per target, capped at 4. Each extra target is represented by an extra tether. | `get_attack_target_cap()`, `PlayerCombat.get_attack_lock_targets()` |
| `stat_intelligence` (Eye) | Telegraph read | Projectile telegraph `pressure_start` pulled earlier by `stat_intelligence - 1.0`, capped at 0.5. Insight buys reading the beat. | `get_telegraph_eye_bias()`, `Projectile._update_visual_state()` |

### Direct (not compound) stat→combat seams
These are simple aliases, not compound interactions; intentionally NOT routed through the calculator.
- `stat_endurance` (Lung) → max stamina pool. `CombatMeter.stamina_max` returns `GameState.stat_endurance` directly.
- `stat_intelligence` (Eye) → support charge gain mult. `RunGrowth._gain_support_charge` multiplies by `stat_intelligence` directly.

## Next Steps
- Wire enemy stat compound effects (region scaling, encounter modifiers) through a parallel seam.
- Add support-related compound (Eye → support readability) if a clamped/capped form is needed.
- Validate after each change.
