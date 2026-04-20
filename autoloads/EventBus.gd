extends Node

# Combat lifecycle
@warning_ignore("unused_signal")
signal combat_started(enemy_data: Array)
@warning_ignore("unused_signal")
signal combat_ended(victory: bool)

# Projectile flow
@warning_ignore("unused_signal")
signal projectile_fired(lane: int, enemy_id: int)
@warning_ignore("unused_signal")
signal projectile_missed(lane: int, damage: float)

# Player actions
@warning_ignore("unused_signal")
signal player_teleported(from_lane: int, to_lane: int)
@warning_ignore("unused_signal")
signal player_attacked(lane: int, damage: float, was_timed: bool)
@warning_ignore("unused_signal")
signal timed_attack_resolved(lane: int, quality: String, damage: float)
@warning_ignore("unused_signal")
signal player_parried(lane: int, quality: String, reflect_damage: float)
@warning_ignore("unused_signal")
signal player_dodged(from_lane: int, to_lane: int)

# Player state
@warning_ignore("unused_signal")
signal player_took_damage(amount: float, source_lane: int)
@warning_ignore("unused_signal")
signal player_died()
@warning_ignore("unused_signal")
signal player_healed(amount: float)
@warning_ignore("unused_signal")
signal player_no_stamina()

# Enemy state
@warning_ignore("unused_signal")
signal enemy_damaged(enemy_id: int, damage: float)
@warning_ignore("unused_signal")
signal enemy_defeated(enemy_id: int)
@warning_ignore("unused_signal")
signal enemy_status_applied(lane: int, status_id: String)
@warning_ignore("unused_signal")
signal enemy_status_cleared(lane: int)

# Combat meter
@warning_ignore("unused_signal")
signal combo_changed(count: int, tier: String)
@warning_ignore("unused_signal")
signal combo_broken(lost: int)
@warning_ignore("unused_signal")
signal style_changed(score: float, tier: String)
@warning_ignore("unused_signal")
signal stamina_changed(current: float, maximum: float)
@warning_ignore("unused_signal")
signal sovereign_reached()
@warning_ignore("unused_signal")
signal ultimate_available()
@warning_ignore("unused_signal")
signal ultimate_fired(power: float)
@warning_ignore("unused_signal")
signal phrase_milestone(count: int)   # consecutive quality action chain: 3 / 5 / 8+
@warning_ignore("unused_signal")
signal tier_changed(new_tier: String, old_tier: String)  # combat tier escalation

# Creature systems
@warning_ignore("unused_signal")
signal capture_offered(creature_data: Dictionary)
@warning_ignore("unused_signal")
signal creature_eaten(creature_data: Dictionary)
@warning_ignore("unused_signal")
signal creature_bonded(creature_data: Dictionary)
@warning_ignore("unused_signal")
signal dna_gained(species_id: String, amount: float, total: float)

# Run
@warning_ignore("unused_signal")
signal run_started(run_number: int)
@warning_ignore("unused_signal")
signal run_growth_changed(level: int, current_exp: float, exp_to_next: float)
@warning_ignore("unused_signal")
signal run_growth_level_resolved(result: Dictionary)
@warning_ignore("unused_signal")
signal tendency_growth_resolved(tendency_id: String, title: String, summary: String)
@warning_ignore("unused_signal")
signal support_charge_changed(current: float, maximum: float, active_species_id: String)
@warning_ignore("unused_signal")
signal dna_routing_changed(route_id: String, label: String)
@warning_ignore("unused_signal")
signal bonded_support_triggered(species_id: String, lane: int, effect_id: String)
@warning_ignore("unused_signal")
signal mastery_context_updated(data: Dictionary)

# Presentation
@warning_ignore("unused_signal")
signal screen_shake(intensity: float, duration: float)
@warning_ignore("unused_signal")
signal screen_flash(color: Color, duration: float)
@warning_ignore("unused_signal")
signal slow_motion(scale: float, duration: float)
@warning_ignore("unused_signal")
signal timing_ring_pressed(lane: int)
@warning_ignore("unused_signal")
signal play_sfx(cue_id: String)
