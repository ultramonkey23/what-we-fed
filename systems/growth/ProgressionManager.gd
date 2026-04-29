extends RefCounted
class_name ProgressionManager

const GROWTH_CONTENT = preload("res://data/RunGrowthContent.gd")

var level: int = 1
var current_exp: float = 0.0
var exp_to_next: float = 125.0 # get_exp_threshold(1)
var dna_routing_preference: String = "bond"

func reset() -> void:
	level = 1
	current_exp = 0.0
	exp_to_next = get_exp_threshold(1)
	dna_routing_preference = "bond"

func grant_exp(amount: float, potential: float) -> int:
	if amount <= 0.0: return 0
	
	# PERSISTENT TRUTH: Meta-Bond Level Multiplier.
	# High Bond levels in the Lair accelerate your Player (Codex) Leveling.
	var bond_mult: float = 1.0 + (GameState.get_total_bond_level() * 0.05)
	
	current_exp += amount * potential * bond_mult
	var levels_gained: int = 0
	var cap: int = GameState.get_codex_level_cap()
	
	while level < cap and current_exp >= exp_to_next:
		current_exp -= exp_to_next
		level += 1
		levels_gained += 1
		exp_to_next = get_exp_threshold(level)

	# Cap handling: If at level cap, current_exp stays at 0 to stop scaling.
	if level >= cap:
		current_exp = 0.0
		
	return levels_gained

func get_exp_threshold(level_value: int) -> float:
	# RESOLUTION TRUTH: Linear scaling for Level 10,000 ceiling.
	# Exponential scaling would break float bounds at level 500+.
	return 100.0 + (float(level_value) * 25.0)
