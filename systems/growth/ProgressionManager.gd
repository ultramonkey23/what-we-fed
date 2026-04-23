extends RefCounted
class_name ProgressionManager

const GROWTH_CONTENT = preload("res://data/RunGrowthContent.gd")

var level: int = 1
var current_exp: float = 0.0
var exp_to_next: float = GROWTH_CONTENT.LEVEL_THRESHOLDS[0]
var dna_routing_preference: String = "bond"

func reset() -> void:
	level = 1
	current_exp = 0.0
	exp_to_next = GROWTH_CONTENT.LEVEL_THRESHOLDS[0]
	dna_routing_preference = "bond"

func grant_exp(amount: float, potential: float) -> bool:
	if amount <= 0.0: return false
	current_exp += amount * potential
	var leveled_up: bool = false
	while level - 1 < GROWTH_CONTENT.LEVEL_THRESHOLDS.size() and current_exp >= exp_to_next:
		current_exp -= exp_to_next
		level += 1
		leveled_up = true
		if level - 1 < GROWTH_CONTENT.LEVEL_THRESHOLDS.size():
			exp_to_next = GROWTH_CONTENT.LEVEL_THRESHOLDS[level - 1]
		else:
			exp_to_next = GROWTH_CONTENT.LEVEL_THRESHOLDS[GROWTH_CONTENT.LEVEL_THRESHOLDS.size() - 1] + 70.0
	return leveled_up

func get_exp_threshold(level_value: int) -> float:
	if level_value - 1 < GROWTH_CONTENT.LEVEL_THRESHOLDS.size():
		return GROWTH_CONTENT.LEVEL_THRESHOLDS[level_value - 1]
	return GROWTH_CONTENT.LEVEL_THRESHOLDS[GROWTH_CONTENT.LEVEL_THRESHOLDS.size() - 1] + 70.0
