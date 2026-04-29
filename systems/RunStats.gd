extends Node

# Score weights — tuned for a typical full run producing ~900-1400 points on solid play.
const SCORE_KILL: int = 20
const SCORE_PERFECT_ATTACK: int = 15
const SCORE_GOOD_ATTACK: int = 8
const SCORE_PERFECT_PARRY: int = 20
const SCORE_GOOD_PARRY: int = 10
const SCORE_ULTIMATE: int = 25
const SCORE_SUPPORT_TRIGGER: int = 12
const SCORE_TENDENCY_SURGE: int = 15

# Grade thresholds (per SONG_LEVEL_STRUCTURE language)
const GRADE_CONTROLLED: int = 300
const GRADE_DOMINANT: int = 700
const GRADE_DEVOURING: int = 1200

signal score_changed(score: int)

var kills: int = 0
var damage_dealt: float = 0.0
var perfect_attacks: int = 0
var good_attacks: int = 0
var perfect_parries: int = 0
var good_parries: int = 0
var ultimates_fired: int = 0
var support_triggers: int = 0
var tendency_surges: int = 0
var times_hit: int = 0
var bonds: int = 0
var eats: int = 0
var dna_gained: float = 0.0
var passes: int = 0
var run_score: int = 0
func _ready() -> void:
	# Initial stats reset.
	reset()

	EventBus.run_started.connect(_on_run_started)
	EventBus.enemy_defeated.connect(_on_enemy_defeated)
	EventBus.enemy_damaged.connect(_on_enemy_damaged)
	EventBus.timed_attack_resolved.connect(_on_timed_attack_resolved)
	EventBus.player_parried.connect(_on_player_parried)
	EventBus.ultimate_fired.connect(_on_ultimate_fired)
	EventBus.bonded_support_triggered.connect(_on_bonded_support_triggered)
	EventBus.tendency_growth_resolved.connect(_on_tendency_growth_resolved)
	EventBus.player_took_damage.connect(_on_player_took_damage)
	EventBus.creature_bonded.connect(_on_creature_bonded)
	EventBus.creature_eaten.connect(_on_creature_eaten)
	EventBus.dna_gained.connect(_on_dna_gained)


func _exit_tree() -> void:
	if EventBus.run_started.is_connected(_on_run_started):
		EventBus.run_started.disconnect(_on_run_started)
	if EventBus.enemy_defeated.is_connected(_on_enemy_defeated):
		EventBus.enemy_defeated.disconnect(_on_enemy_defeated)
	if EventBus.enemy_damaged.is_connected(_on_enemy_damaged):
		EventBus.enemy_damaged.disconnect(_on_enemy_damaged)
	if EventBus.timed_attack_resolved.is_connected(_on_timed_attack_resolved):
		EventBus.timed_attack_resolved.disconnect(_on_timed_attack_resolved)
	if EventBus.player_parried.is_connected(_on_player_parried):
		EventBus.player_parried.disconnect(_on_player_parried)
	if EventBus.ultimate_fired.is_connected(_on_ultimate_fired):
		EventBus.ultimate_fired.disconnect(_on_ultimate_fired)
	if EventBus.bonded_support_triggered.is_connected(_on_bonded_support_triggered):
		EventBus.bonded_support_triggered.disconnect(_on_bonded_support_triggered)
	if EventBus.tendency_growth_resolved.is_connected(_on_tendency_growth_resolved):
		EventBus.tendency_growth_resolved.disconnect(_on_tendency_growth_resolved)
	if EventBus.player_took_damage.is_connected(_on_player_took_damage):
		EventBus.player_took_damage.disconnect(_on_player_took_damage)
	if EventBus.creature_bonded.is_connected(_on_creature_bonded):
		EventBus.creature_bonded.disconnect(_on_creature_bonded)
	if EventBus.creature_eaten.is_connected(_on_creature_eaten):
		EventBus.creature_eaten.disconnect(_on_creature_eaten)
	if EventBus.dna_gained.is_connected(_on_dna_gained):
		EventBus.dna_gained.disconnect(_on_dna_gained)


func reset() -> void:
	kills = 0
	damage_dealt = 0.0
	perfect_attacks = 0
	good_attacks = 0
	perfect_parries = 0
	good_parries = 0
	ultimates_fired = 0
	support_triggers = 0
	tendency_surges = 0
	times_hit = 0
	bonds = 0
	eats = 0
	dna_gained = 0.0
	passes = 0
	run_score = 0
	emit_signal("score_changed", run_score)


func get_grade() -> String:
	if run_score >= GRADE_DEVOURING:
		return "DEVOURING"
	elif run_score >= GRADE_DOMINANT:
		return "DOMINANT"
	elif run_score >= GRADE_CONTROLLED:
		return "CONTROLLED"
	return "BARELY HELD"


func get_compact_summary() -> Dictionary:
	var total_perfects: int = perfect_attacks + perfect_parries
	return {
		"grade": get_grade(),
		"score": run_score,
		"kills": kills,
		"hits": times_hit,
		"perfects": total_perfects,
		"support_triggers": support_triggers,
		"passes": passes
	}


func _add_score(amount: int) -> void:
	if amount <= 0:
		return
	run_score += amount
	emit_signal("score_changed", run_score)


func _on_run_started(_run_number: int) -> void:
	reset()


func _on_enemy_defeated(_enemy_id: int) -> void:
	kills += 1
	_add_score(SCORE_KILL)


func _on_enemy_damaged(_enemy_id: int, damage: float) -> void:
	damage_dealt += damage


func _on_timed_attack_resolved(_lane: int, quality: String, _damage: float, _enemy_id: int) -> void:
	if quality == "perfect":
		perfect_attacks += 1
		_add_score(SCORE_PERFECT_ATTACK)
	elif quality == "good":
		good_attacks += 1
		_add_score(SCORE_GOOD_ATTACK)


func _on_player_parried(_lane: int, quality: String, _reflect_damage: float) -> void:
	if quality == "perfect":
		perfect_parries += 1
		_add_score(SCORE_PERFECT_PARRY)
	elif quality == "good":
		good_parries += 1
		_add_score(SCORE_GOOD_PARRY)


func _on_ultimate_fired(_power: float) -> void:
	ultimates_fired += 1
	_add_score(SCORE_ULTIMATE)


func _on_bonded_support_triggered(_species_id: String, _lane: int, _effect_id: String) -> void:
	support_triggers += 1
	_add_score(SCORE_SUPPORT_TRIGGER)


func _on_tendency_growth_resolved(_tendency_id: String, _title: String, _summary: String) -> void:
	tendency_surges += 1
	_add_score(SCORE_TENDENCY_SURGE)


func _on_player_took_damage(_amount: float, _source_lane: int) -> void:
	times_hit += 1


func _on_creature_bonded(_creature_data: Dictionary) -> void:
	bonds += 1


func _on_creature_eaten(_creature_data: Dictionary) -> void:
	eats += 1


func _on_dna_gained(_species_id: String, amount: float, _total: float) -> void:
	dna_gained += amount
