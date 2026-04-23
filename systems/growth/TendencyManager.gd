extends RefCounted
class_name TendencyManager

const GROWTH_CONTENT = preload("res://data/RunGrowthContent.gd")

var points: Dictionary = {
	"aggression": 0.0,
	"cadence": 0.0,
	"guard": 0.0,
	"bond": 0.0
}
var levels: Dictionary = {
	"aggression": 0,
	"cadence": 0,
	"guard": 0,
	"bond": 0
}
var active_surges: Dictionary = {
	"aggression": 0.0,
	"cadence": 0.0,
	"guard": 0.0,
	"bond": 0.0
}

func reset(default_surges: Dictionary = {}) -> void:
	points = {"aggression": 0.0, "cadence": 0.0, "guard": 0.0, "bond": 0.0}
	levels = {"aggression": 0, "cadence": 0, "guard": 0, "bond": 0}
	active_surges = {
		"aggression": float(default_surges.get("aggression", 0.0)),
		"cadence": float(default_surges.get("cadence", 0.0)),
		"guard": float(default_surges.get("guard", 0.0)),
		"bond": float(default_surges.get("bond", 0.0))
	}

func grant_points(tendency_id: String, amount: float, potential: float) -> void:
	if amount <= 0.0 or not points.has(tendency_id): return
	points[tendency_id] += amount * potential

func get_leading_id(is_bonded: bool) -> String:
	var best_id: String = ""
	var best_value: float = -1.0
	for tendency_id in points.keys():
		var value: float = float(points.get(tendency_id, 0.0))
		if tendency_id == "bond" and is_bonded: value += 0.35
		if value > best_value:
			best_value = value
			best_id = tendency_id
	return best_id

func get_sorted_ids() -> Array[String]:
	var ids: Array[String] = ["aggression", "cadence", "guard", "bond"]
	ids.sort_custom(func(a: String, b: String) -> bool:
		var a_level: int = int(levels.get(a, 0))
		var b_level: int = int(levels.get(b, 0))
		if a_level == b_level: return float(points.get(a, 0.0)) > float(points.get(b, 0.0))
		return a_level > b_level
	)
	return ids

func process_surges(delta: float) -> void:
	if active_surges.get("cadence", 0.0) > 0.0:
		active_surges["cadence"] = max(active_surges["cadence"] - delta, 0.0)

func consume_surge_hit(surge_type: String) -> void:
	if active_surges.has(surge_type):
		active_surges[surge_type] = max(active_surges[surge_type] - 1.0, 0.0)
