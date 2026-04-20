extends Node

# Advanced Mutation Synergy System - Complex mutation interactions and combinations
# This system provides deep mutation synergies, combo effects, and strategic depth

signal synergy_activated(synergy_data: Dictionary)
signal synergy_deactivated(synergy_id: String)
signal combo_achieved(combo_data: Dictionary)
signal mutation_evolution(evolution_data: Dictionary)

# Synergy definitions with complex interactions
const MUTATION_SYNERGIES := {
	# Damage-focused synergies
	"perfect_storm": {
		"required_mutations": ["timed_damage_flat", "stamina_on_perfect_parry"],
		"bonus_effect": {"type": "damage_on_perfect", "value": 5.0, "stacks": true},
		"description": "Perfect timing deals bonus damage and restores stamina",
		"synergy_type": "damage",
		"activation_threshold": 2
	},
	"vampiric_precision": {
		"required_mutations": ["timed_damage_flat", "heal_on_hit_taken"],
		"bonus_effect": {"type": "lifesteal_on_timed", "value": 0.25},
		"description": "Timed hits heal for 25% of damage dealt",
		"synergy_type": "survival",
		"activation_threshold": 2
	},
	# Defense-focused synergies
	"iron_wall": {
		"required_mutations": ["heal_on_hit_taken", "damage_reduction"],
		"bonus_effect": {"type": "adaptive_defense", "value": 0.15},
		"description": "Taking damage increases defense temporarily",
		"synergy_type": "defense",
		"activation_threshold": 2
	},
	"regenerative_fortress": {
		"required_mutations": ["heal_on_hit_taken", "support_charge_mult_on_kill"],
		"bonus_effect": {"type": "passive_regen", "value": 2.0},
		"description": "Passive health regeneration when both mutations active",
		"synergy_type": "survival",
		"activation_threshold": 2
	},
	# Utility synergies
	"efficiency_master": {
		"required_mutations": ["support_charge_mult_on_kill", "ultimate_charge_mult"],
		"bonus_effect": {"type": "resource_efficiency", "value": 0.3},
		"description": "30% more efficient resource generation",
		"synergy_type": "utility",
		"activation_threshold": 2
	},
	"combo_chain": {
		"required_mutations": ["timed_damage_flat", "support_charge_mult_on_kill", "ultimate_charge_mult"],
		"bonus_effect": {"type": "combo_multiplier", "value": 1.5},
		"description": "Combo attacks multiply all resource gains",
		"synergy_type": "combo",
		"activation_threshold": 3
	},
	# Advanced synergies (3+ mutations)
	"trinity_power": {
		"required_mutations": ["timed_damage_flat", "heal_on_hit_taken", "support_charge_mult_on_kill"],
		"bonus_effect": {"type": "trinity_boost", "damage": 3.0, "heal": 5.0, "support": 0.5},
		"description": "Boosts damage, healing, and support generation",
		"synergy_type": "master",
		"activation_threshold": 3
	},
	"perfect_balance": {
		"required_mutations": ["timed_damage_flat", "stamina_on_perfect_parry", "heal_on_hit_taken"],
		"bonus_effect": {"type": "balance_orb", "duration": 8.0, "effect_radius": 100.0},
		"description": "Creates a balance orb that aids both offense and defense",
		"synergy_type": "master",
		"activation_threshold": 3
	}
}

# Combo chains for advanced interactions
const COMBO_CHAINS := {
	"offensive_ramp": {
		"sequence": ["perfect_timing", "timed_hit", "perfect_timing"],
		"reward": {"type": "damage_boost", "value": 2.0, "duration": 10.0},
		"description": "Chain perfect timing for damage boost"
	},
	"defensive_cycle": {
		"sequence": ["hit_taken", "perfect_parry", "hit_taken"],
		"reward": {"type": "defense_boost", "value": 0.5, "duration": 8.0},
		"description": "Complete defensive cycle for protection"
	},
	"resource_flow": {
		"sequence": ["enemy_defeated", "timed_hit", "ultimate_activation"],
		"reward": {"type": "resource_refund", "percentage": 0.25},
		"description": "Optimal resource flow for cost reduction"
	}
}

# Evolution paths for mutations
const MUTATION_EVOLUTIONS := {
	"ashclaw_frenzy_evolution": {
		"base_mutation": "ashclaw_frenzy",
		"required_usage": 15,
		"evolved_mutation": "ashclaw_berserk",
		"bonus_stats": {"damage": 8.0, "charges": 18, "duration": 15.0},
		"description": "Evolve to berserk mode with enhanced power"
	},
	"remnant_mend_evolution": {
		"base_mutation": "remnant_mend",
		"required_usage": 12,
		"evolved_mutation": "remnant_rebirth",
		"bonus_stats": {"heal": 10.0, "charges": 6, "area_effect": true},
		"description": "Evolve to rebirth with area healing"
	}
}

# Active synergies and tracking
var active_synergies: Dictionary = {}
var synergy_history: Dictionary = {}
var combo_progress: Dictionary = {}
var evolution_progress: Dictionary = {}

func _ready() -> void:
	# Initialize tracking systems
	_reset_tracking_data()

func _reset_tracking_data() -> void:
	active_synergies.clear()
	synergy_history.clear()
	combo_progress.clear()
	evolution_progress.clear()
	
	# Initialize combo progress tracking
	for combo_id in COMBO_CHAINS:
		combo_progress[combo_id] = {"current_index": 0, "active": false}

# Check for new synergies based on active mutations
func check_synergies(active_mutations: Array[Dictionary]) -> Array[Dictionary]:
	var new_synergies: Array[Dictionary] = []
	var active_mutation_ids: Array[String] = []
	
	# Extract active mutation IDs
	for mutation in active_mutations:
		if mutation.get("current_charges", 0) > 0:
			active_mutation_ids.append(mutation.get("id", ""))
	
	# Check each potential synergy
	for synergy_id in MUTATION_SYNERGIES:
		if not active_synergies.has(synergy_id):
			var synergy_data: Dictionary = MUTATION_SYNERGIES[synergy_id]
			var required_mutations: Array[String] = synergy_data.get("required_mutations", [])
			var activation_threshold: int = synergy_data.get("activation_threshold", 2)
			
			# Count how many required mutations are active
			var active_count: int = 0
			for required_id in required_mutations:
				if required_id in active_mutation_ids:
					active_count += 1
			
			# Activate synergy if threshold met
			if active_count >= activation_threshold:
				var synergy_instance: Dictionary = _create_synergy_instance(synergy_id, synergy_data)
				active_synergies[synergy_id] = synergy_instance
				new_synergies.append(synergy_instance)
				synergy_activated.emit(synergy_instance)
	
	return new_synergies

func _create_synergy_instance(synergy_id: String, synergy_data: Dictionary) -> Dictionary:
	var instance: Dictionary = synergy_data.duplicate(true)
	instance["synergy_id"] = synergy_id
	instance["activated_at"] = Time.get_unix_time_from_system()
	instance["active"] = true
	instance["total_uses"] = 0
	instance["last_used"] = 0.0
	
	return instance

# Process combo chains based on game events
func process_combo_event(event_type: String, _context: Dictionary = {}) -> Dictionary:
	var completed_combos: Array[Dictionary] = []
	
	# Check each combo chain
	for combo_id in COMBO_CHAINS:
		var combo_data: Dictionary = COMBO_CHAINS[combo_id]
		var sequence: Array[String] = combo_data.get("sequence", [])
		var progress: Dictionary = combo_progress[combo_id]
		
		# Check if current event matches next in sequence
		if progress.get("current_index", 0) < sequence.size():
			var expected_event: String = sequence[progress.get("current_index", 0)]
			
			if event_type == expected_event:
				progress.current_index += 1
				
				# Check if combo completed
				if progress.current_index >= sequence.size():
					var completed_combo: Dictionary = _complete_combo(combo_id, combo_data)
					completed_combos.append(completed_combo)
					combo_achieved.emit(completed_combo)
					
					# Reset progress
					progress.current_index = 0
					progress.active = false
				else:
					# Mark combo as in progress
					progress.active = true
			else:
				# Reset progress if event doesn't match
				progress.current_index = 0
				progress.active = false
	
	return {"completed_combos": completed_combos, "active_progress": combo_progress}

func _complete_combo(combo_id: String, combo_data: Dictionary) -> Dictionary:
	var completed_combo: Dictionary = combo_data.duplicate(true)
	completed_combo["combo_id"] = combo_id
	completed_combo["completed_at"] = Time.get_unix_time_from_system()
	var history_entry: Dictionary = synergy_history.get(combo_id) if synergy_history.has(combo_id) else {"total_completions": 0, "last_completion": 0.0}
	completed_combo["total_completions"] = history_entry.get("total_completions", 0) + 1
	
	# Track in history
	if not synergy_history.has(combo_id):
		synergy_history[combo_id] = {"total_completions": 0, "last_completion": 0.0}
	synergy_history[combo_id]["total_completions"] = completed_combo.total_completions
	synergy_history[combo_id]["last_completion"] = completed_combo.completed_at
	
	return completed_combo

# Check for mutation evolution
func check_evolution(mutation_id: String, usage_count: int) -> Dictionary:
	var evolution_data: Dictionary = {}
	
	# Check if mutation has evolution path
	for evolution_id in MUTATION_EVOLUTIONS:
		var evolution: Dictionary = MUTATION_EVOLUTIONS[evolution_id]
		if evolution.get("base_mutation", "") == mutation_id:
			var required_usage: int = evolution.get("required_usage", 10)
			
			if usage_count >= required_usage:
				evolution_data = evolution.duplicate(true)
				evolution_data["evolution_id"] = evolution_id
				evolution_data["evolved_at"] = Time.get_unix_time_from_system()
				evolution_data["trigger_usage"] = usage_count
				
				mutation_evolution.emit(evolution_data)
				break
	
	return evolution_data

# Apply synergy effects
func apply_synergy_effects(synergy_id: String, context: Dictionary = {}) -> Dictionary:
	if not active_synergies.has(synergy_id):
		return {}
	
	var synergy: Dictionary = active_synergies[synergy_id]
	var effect: Dictionary = synergy.get("bonus_effect", {})
	var result: Dictionary = {}
	
	match effect.get("type", ""):
		"damage_on_perfect":
			if context.get("is_perfect", false):
				result["damage_bonus"] = effect.get("value", 0.0)
				synergy["total_uses"] += 1
				synergy["last_used"] = Time.get_unix_time_from_system()
		
		"lifesteal_on_timed":
			if context.get("is_timed", false):
				var damage: float = context.get("damage", 0.0)
				result["heal_amount"] = damage * effect.get("value", 0.0)
				synergy["total_uses"] += 1
				synergy["last_used"] = Time.get_unix_time_from_system()
		
		"adaptive_defense":
			if context.get("damage_taken", 0.0) > 0:
				result["defense_boost"] = effect.get("value", 0.0)
				synergy["total_uses"] += 1
				synergy["last_used"] = Time.get_unix_time_from_system()
		
		"passive_regen":
			result["regen_rate"] = effect.get("value", 0.0)
		
		"resource_efficiency":
			result["efficiency_boost"] = effect.get("value", 0.0)
		
		"combo_multiplier":
			if context.get("is_combo", false):
				result["multiplier"] = effect.get("value", 1.0)
				synergy["total_uses"] += 1
				synergy["last_used"] = Time.get_unix_time_from_system()
		
		"trinity_boost":
			result["damage_boost"] = effect.get("damage", 0.0)
			result["heal_boost"] = effect.get("heal", 0.0)
			result["support_boost"] = effect.get("support", 0.0)
			synergy["total_uses"] += 1
			synergy["last_used"] = Time.get_unix_time_from_system()
		
		"balance_orb":
			result["orb_duration"] = effect.get("duration", 0.0)
			result["orb_radius"] = effect.get("effect_radius", 0.0)
			synergy["total_uses"] += 1
			synergy["last_used"] = Time.get_unix_time_from_system()
	
	return result

# Get active synergy data for UI
func get_active_synergy_data() -> Dictionary:
	var ui_data: Dictionary = {}
	
	for synergy_id in active_synergies:
		var synergy: Dictionary = active_synergies[synergy_id]
		ui_data[synergy_id] = {
			"name": synergy_id,
			"description": synergy.get("description", ""),
			"type": synergy.get("synergy_type", ""),
			"total_uses": synergy.get("total_uses", 0),
			"last_used": synergy.get("last_used", 0.0),
			"active": synergy.get("active", false)
		}
	
	return ui_data

# Get combo progress for UI
func get_combo_progress_data() -> Dictionary:
	var progress_data: Dictionary = {}
	
	for combo_id in combo_progress:
		var progress: Dictionary = combo_progress[combo_id]
		var combo_data: Dictionary = COMBO_CHAINS[combo_id]
		
		progress_data[combo_id] = {
			"name": combo_id,
			"description": combo_data.get("description", ""),
			"current_index": progress.get("current_index", 0),
			"total_steps": combo_data.get("sequence", []).size(),
			"active": progress.get("active", false),
			"progress_percentage": float(progress.get("current_index", 0)) / float(combo_data.get("sequence", []).size()) * 100.0
		}
	
	return progress_data

# Get evolution progress
func get_evolution_progress_data() -> Dictionary:
	return evolution_progress.duplicate(true)

# Deactivate synergy (when mutations are depleted)
func deactivate_synergy(synergy_id: String) -> void:
	if active_synergies.has(synergy_id):
		active_synergies[synergy_id]["active"] = false
		synergy_deactivated.emit(synergy_id)

# Reset all synergy data
func reset_synergies() -> void:
	_reset_tracking_data()
