extends Node

# Combat lifecycle
signal combat_started(enemy_data: Array)
signal combat_ended(victory: bool)

# Projectile flow
signal projectile_fired(lane: int, enemy_id: int)
signal projectile_missed(lane: int, damage: float)

# Player actions
signal player_teleported(from_lane: int, to_lane: int)
signal player_attacked(lane: int, damage: float, was_timed: bool)
signal timed_attack_resolved(lane: int, quality: String, damage: float)
signal player_parried(lane: int, quality: String, reflect_damage: float)
signal player_dodged(from_lane: int, to_lane: int)

# Player state
signal player_took_damage(amount: float, source_lane: int)
signal player_died()
signal player_healed(amount: float)
signal player_no_stamina()

# Enemy state
signal enemy_damaged(enemy_id: int, damage: float)
signal enemy_defeated(enemy_id: int)

# Combat meter
signal combo_changed(count: int, tier: String)
signal combo_broken(lost: int)
signal style_changed(score: float, tier: String)
signal stamina_changed(current: float, maximum: float)
signal sovereign_reached()
signal ultimate_available()
signal ultimate_fired(power: float)

# Creature systems
signal capture_offered(creature_data: Dictionary)
signal creature_eaten(creature_data: Dictionary)
signal creature_bonded(creature_data: Dictionary)

# Run
signal run_started(run_number: int)
signal run_growth_changed(level: int, exp: float, exp_to_next: float)
signal support_charge_changed(current: float, maximum: float, active_species_id: String)
signal bonded_support_triggered(species_id: String, lane: int, effect_id: String)
signal run_upgrade_taken(upgrade_id: String)

# Presentation
signal screen_shake(intensity: float, duration: float)
signal screen_flash(color: Color, duration: float)
signal slow_motion(scale: float, duration: float)
signal timing_ring_pressed(lane: int)
