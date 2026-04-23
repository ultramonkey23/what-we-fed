extends RefCounted
class_name SupportManager

const GROWTH_CONTENT = preload("res://data/RunGrowthContent.gd")

var charge: float = 0.0
var max_charge: float = GROWTH_CONTENT.SUPPORT_MAX

func reset(initial_charge: float = 0.0) -> void:
	charge = clamp(initial_charge, 0.0, max_charge)

func gain_charge(amount: float, mult: float) -> void:
	if amount <= 0.0: return
	charge = clamp(charge + amount * mult, 0.0, max_charge)

func is_ready() -> bool:
	return charge >= max_charge

func consume() -> void:
	charge = 0.0
