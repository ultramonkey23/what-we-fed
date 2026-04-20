extends Node

# Enhanced Mutation Tracker - Better tracking and visual feedback for mutation mechanics
# This system provides detailed mutation state management and UI feedback

signal mutation_activated(mutation_data: Dictionary)
signal mutation_charge_consumed(mutation_id: String, charges_remaining: int)
signal mutation_depleted(mutation_id: String)
signal mutation_synergy_detected(synergy_data: Dictionary)
signal mutation_feedback_requested(text: String, color: Color)

const COMBAT_FEEL_CONSTANTS = preload("res://data/CombatFeelConstants.gd")

# Enhanced mutation data structure
var active_mutations: Array[Dictionary] = []
var mutation_history: Array[Dictionary] = []
var synergy_combinations: Array[Dictionary] = []
var mutation_ui_data: Dictionary = {}

# Mutation state tracking
var mutation_timers: Dictionary = {}
var regeneration_timers: Dictionary = {}
var visual_feedback_queue: Array[Dictionary] = []

func _ready() -> void:
	# Connect to EventBus for relevant combat events
	if not EventBus.player_attacked.is_connected(_on_player_action):
		EventBus.player_attacked.connect(_on_player_action)
	if not EventBus.player_parried.is_connected(_on_player_action):
		EventBus.player_parried.connect(_on_player_action)
	if not EventBus.enemy_defeated.is_connected(_on_enemy_defeated):
		EventBus.enemy_defeated.connect(_on_enemy_defeated)
	if not EventBus.ultimate_fired.is_connected(_on_ultimate_fired):
		EventBus.ultimate_fired.connect(_on_ultimate_fired)

func add_mutation(mutation_data: Dictionary) -> void:
	var enhanced_mutation: Dictionary = _enhance_mutation_data(mutation_data)
	active_mutations.append(enhanced_mutation)
	
	# Track mutation history
	var history_entry: Dictionary = {
		"mutation_id": enhanced_mutation.get("id", ""),
		"timestamp": Time.get_unix_time_from_system(),
		"source": enhanced_mutation.get("source_species", "unknown"),
		"initial_charges": enhanced_mutation.get("current_charges", 0)
	}
	mutation_history.append(history_entry)
	
	# Initialize UI data
	_initialize_mutation_ui(enhanced_mutation)
	
	# Check for synergies
	_check_mutation_synergies()
	
	mutation_activated.emit(enhanced_mutation)

func _enhance_mutation_data(mutation_data: Dictionary) -> Dictionary:
	var enhanced: Dictionary = mutation_data.duplicate(true)
	
	# Add tracking fields
	enhanced["activation_time"] = Time.get_unix_time_from_system()
	enhanced["total_consumed"] = 0
	enhanced["times_triggered"] = 0
	enhanced["last_trigger_time"] = 0.0
	enhanced["is_active"] = true
	enhanced["visual_intensity"] = 1.0
	
	# Add regeneration data if applicable
	var effect: Dictionary = enhanced.get("effect", {})
	if effect.has("regeneration_time"):
		enhanced["regeneration_time"] = effect["regeneration_time"]
		enhanced["last_regeneration"] = Time.get_unix_time_from_system()
	
	return enhanced

func _initialize_mutation_ui(mutation_data: Dictionary) -> void:
	var mutation_id: String = mutation_data.get("id", "")
	
	mutation_ui_data[mutation_id] = {
		"display_name": mutation_data.get("display_name", "Unknown Mutation"),
		"summary": mutation_data.get("summary", ""),
		"current_charges": mutation_data.get("current_charges", 0),
		"max_charges": _get_max_charges(mutation_data),
		"is_available": true,
		"glow_intensity": 0.0,
		"pulse_speed": 1.0,
		"color_tint": _get_mutation_color(mutation_data),
		"synergy_active": false,
		"usage_frequency": 0.0
	}

func _get_max_charges(mutation_data: Dictionary) -> int:
	var effect: Dictionary = mutation_data.get("effect", {})
	return int(effect.get("charges", 0))

func _get_mutation_color(mutation_data: Dictionary) -> Color:
	var effect_type: String = mutation_data.get("effect", {}).get("type", "")
	
	match effect_type:
		"timed_damage_flat":
			return Color(1.0, 0.3, 0.2, 1.0)  # Red for damage
		"heal_on_hit_taken":
			return Color(0.2, 1.0, 0.4, 1.0)  # Green for healing
		"stamina_on_perfect_parry":
			return Color(0.2, 0.8, 1.0, 1.0)  # Blue for stamina
		"support_charge_mult_on_kill":
			return Color(1.0, 0.8, 0.2, 1.0)  # Yellow for support
		_:
			return Color(0.8, 0.6, 1.0, 1.0)  # Purple for unknown

func consume_mutation_charge(mutation_id: String, amount: int = 1, trigger_context: String = "") -> bool:
	for i in range(active_mutations.size()):
		var mutation: Dictionary = active_mutations[i]
		if String(mutation.get("id", "")) == mutation_id:
			var charges: int = int(mutation.get("current_charges", 0))
			
			if charges >= amount:
				# Consume charges
				mutation["current_charges"] = max(0, charges - amount)
				mutation["total_consumed"] += amount
				mutation["times_triggered"] += 1
				mutation["last_trigger_time"] = Time.get_unix_time_from_system()
				
				# Update UI data
				_update_mutation_ui_consumption(mutation_id, mutation["current_charges"])
				
				# Trigger visual feedback
				_trigger_consumption_feedback(mutation, trigger_context)
				
				# Emit signals
				mutation_charge_consumed.emit(mutation_id, mutation["current_charges"])
				
				# Check if depleted
				if mutation["current_charges"] <= 0:
					mutation["is_active"] = false
					mutation_depleted.emit(mutation_id)
					_trigger_depletion_feedback(mutation)
				
				return true
			else:
				# Not enough charges - trigger feedback
				_trigger_insufficient_charges_feedback(mutation)
				return false
	
	return false

func _update_mutation_ui_consumption(mutation_id: String, remaining_charges: int) -> void:
	if not mutation_ui_data.has(mutation_id):
		return
	
	var ui_data: Dictionary = mutation_ui_data[mutation_id]
	ui_data["current_charges"] = remaining_charges
	ui_data["is_available"] = remaining_charges > 0
	
	# Calculate usage frequency
	var mutation: Dictionary = _get_mutation_by_id(mutation_id)
	if not mutation.is_empty():
		var time_active: float = Time.get_unix_time_from_system() - mutation.get("activation_time", 0)
		var usage_rate: float = float(mutation.get("times_triggered", 0)) / max(time_active, 1.0)
		ui_data["usage_frequency"] = usage_rate
	
	# Trigger visual pulse
	ui_data["glow_intensity"] = 1.0
	ui_data["pulse_speed"] = 2.0

func _trigger_consumption_feedback(mutation: Dictionary, context: String) -> void:
	var mutation_id: String = mutation.get("id", "")
	var display_name: String = mutation.get("display_name", "Mutation")
	var remaining_charges: int = mutation.get("current_charges", 0)
	
	# Create feedback text
	var feedback_text: String = display_name
	if remaining_charges > 0:
		feedback_text += " (" + str(remaining_charges) + ")"
	else:
		feedback_text += " DEPLETED"
	
	var color: Color = _get_mutation_color(mutation)
	
	# Add context-specific modifiers
	match context:
		"perfect_timing":
			color = color.lightened(0.3)
		"critical_hit":
			color = color.lightened(0.5)
		"boss_encounter":
			color = color.darkened(0.2)
	
	mutation_feedback_requested.emit(feedback_text, color)
	
	# Queue visual effect
	visual_feedback_queue.append({
		"type": "consumption",
		"mutation_id": mutation_id,
		"intensity": 1.0,
		"color": color,
		"duration": 0.3
	})

func _trigger_depletion_feedback(mutation: Dictionary) -> void:
	var display_name: String = mutation.get("display_name", "Mutation")
	var color: Color = Color(0.8, 0.2, 0.2, 1.0)  # Red for depletion
	
	mutation_feedback_requested.emit(display_name + " EXHAUSTED", color)
	
	# Queue depletion effect
	visual_feedback_queue.append({
		"type": "depletion",
		"mutation_id": mutation.get("id", ""),
		"intensity": 1.5,
		"color": color,
		"duration": 0.5
	})

func _trigger_insufficient_charges_feedback(mutation: Dictionary) -> void:
	var display_name: String = mutation.get("display_name", "Mutation")
	var color: Color = Color(0.6, 0.6, 0.6, 1.0)  # Gray for insufficient
	
	mutation_feedback_requested.emit(display_name + " NO CHARGES", color)

func _check_mutation_synergies() -> void:
	var active_effect_types: Array[String] = []
	
	for mutation in active_mutations:
		if mutation.get("is_active", false):
			var effect_type: String = mutation.get("effect", {}).get("type", "")
			if not effect_type.is_empty():
				active_effect_types.append(effect_type)
	
	# Check for known synergy combinations
	var known_synergies: Array[Dictionary] = [
		{
			"combination": ["timed_damage_flat", "stamina_on_perfect_parry"],
			"bonus_type": "damage_on_perfect",
			"bonus_value": 3.0,
			"name": "Perfect Strike Synergy"
		},
		{
			"combination": ["heal_on_hit_taken", "support_charge_mult_on_kill"],
			"bonus_type": "heal_on_kill",
			"bonus_value": 2.0,
			"name": "Sustained Aggression"
		},
		{
			"combination": ["timed_damage_flat", "heal_on_hit_taken"],
			"bonus_type": "lifesteal_on_timed",
			"bonus_value": 0.15,
			"name": "Vampiric Precision"
		}
	]
	
	for synergy in known_synergies:
		var required_types: Array = synergy.get("combination", [])
		var has_all_required: bool = true
		
		for required_type in required_types:
			if not required_type in active_effect_types:
				has_all_required = false
				break
		
		if has_all_required and not synergy in synergy_combinations:
			synergy_combinations.append(synergy)
			_activate_synergy(synergy)

func _activate_synergy(synergy_data: Dictionary) -> void:
	var synergy_name: String = synergy_data.get("name", "Synergy")
	var color: Color = Color(1.0, 0.8, 0.2, 1.0)  # Gold for synergies
	
	mutation_feedback_requested.emit(synergy_name + " ACTIVATED", color)
	mutation_synergy_detected.emit(synergy_data)
	
	# Update UI for affected mutations
	for mutation_id in mutation_ui_data:
		mutation_ui_data[mutation_id]["synergy_active"] = true
		mutation_ui_data[mutation_id]["glow_intensity"] = 0.8

func _on_player_action(_lane: int, _damage: float, was_timed: bool) -> void:
	var context: String = "standard" if not was_timed else "perfect_timing"
	_process_mutation_triggers("player_action", context)

func _on_enemy_defeated(_enemy_id: int) -> void:
	_process_mutation_triggers("enemy_defeated", "kill")

func _on_ultimate_fired(_power: float) -> void:
	_process_mutation_triggers("ultimate_fired", "ultimate")

func _process_mutation_triggers(trigger_event: String, context: String) -> void:
	for mutation in active_mutations:
		if not mutation.get("is_active", false):
			continue
		
		var effect: Dictionary = mutation.get("effect", {})
		var effect_type: String = effect.get("type", "")
		var charges: int = mutation.get("current_charges", 0)
		
		if charges <= 0:
			continue
		
		var should_trigger: bool = false
		
		match trigger_event:
			"player_action":
				should_trigger = effect_type in ["timed_damage_flat", "stamina_on_perfect_parry"]
			"enemy_defeated":
				should_trigger = effect_type == "support_charge_mult_on_kill"
			"ultimate_fired":
				should_trigger = effect_type == "damage_on_ultimate"
		
		if should_trigger:
			consume_mutation_charge(mutation.get("id", ""), 1, context)

func get_mutation_ui_data(mutation_id: String) -> Dictionary:
	return mutation_ui_data.get(mutation_id, {})

func get_all_mutation_ui_data() -> Dictionary:
	return mutation_ui_data.duplicate(true)

func get_active_synergies() -> Array[Dictionary]:
	return synergy_combinations.duplicate(true)

func get_mutation_statistics() -> Dictionary:
	var total_mutations: int = active_mutations.size()
	var active_mutations_count: int = 0
	var total_charges_consumed: int = 0
	var most_used_mutation: String = ""
	var max_usage: int = 0
	
	for mutation in active_mutations:
		if mutation.get("is_active", false):
			active_mutations_count += 1
		
		total_charges_consumed += mutation.get("total_consumed", 0)
		
		var usage_count: int = mutation.get("times_triggered", 0)
		if usage_count > max_usage:
			max_usage = usage_count
			most_used_mutation = mutation.get("display_name", "")
	
	return {
		"total_mutations": total_mutations,
		"active_mutations": active_mutations_count,
		"total_charges_consumed": total_charges_consumed,
		"most_used_mutation": most_used_mutation,
		"active_synergies": synergy_combinations.size()
	}

func _get_mutation_by_id(mutation_id: String) -> Dictionary:
	for mutation in active_mutations:
		if String(mutation.get("id", "")) == mutation_id:
			return mutation
	return {}

func _process(delta: float) -> void:
	# Process visual feedback queue
	if not visual_feedback_queue.is_empty():
		var feedback: Dictionary = visual_feedback_queue[0]
		feedback["duration"] -= delta
		
		if feedback["duration"] <= 0:
			visual_feedback_queue.pop_front()
	
	# Update mutation UI animations
	for mutation_id in mutation_ui_data:
		var ui_data: Dictionary = mutation_ui_data[mutation_id]
		
		# Decay glow intensity
		if ui_data.get("glow_intensity", 0.0) > 0:
			ui_data["glow_intensity"] = max(0.0, ui_data["glow_intensity"] - delta * 2.0)
		
		# Normalize pulse speed
		if ui_data.get("pulse_speed", 1.0) > 1.0:
			ui_data["pulse_speed"] = max(1.0, ui_data["pulse_speed"] - delta * 3.0)

func reset_mutations() -> void:
	active_mutations.clear()
	mutation_history.clear()
	synergy_combinations.clear()
	mutation_ui_data.clear()
	mutation_timers.clear()
	regeneration_timers.clear()
	visual_feedback_queue.clear()
