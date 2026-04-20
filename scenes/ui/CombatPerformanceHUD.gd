extends Control

const PERFORMANCE_REWARD_CONTENT = preload("res://data/PerformanceRewardContent.gd")
const UI_STYLE = preload("res://systems/UIStyle.gd")

var _director: Node = null
var _proc_chip_timer: float = 0.0
var _proc_tween: Tween = null

@onready var _shell: Control = %PerformanceShell
@onready var _caption: Label = %Caption
@onready var _progress_label: Label = %ProgressLabel
@onready var _status_label: Label = %StatusLabel
@onready var _claims_label: Label = %ClaimsLabel
@onready var _proc_chip_label: Label = %ProcChipLabel

@onready var _offer_shell: Control = %OfferShell
@onready var _offer_title_label: Label = %OfferTitleLabel
@onready var _offer_body_label: Label = %OfferBodyLabel
@onready var _offer_hint_label: Label = %OfferHintLabel
@onready var _offer_progress_bar: ProgressBar = %OfferProgressBar


func _ready() -> void:
	_shell.visible = false
	_offer_shell.visible = false
	if _proc_chip_label != null:
		_proc_chip_label.visible = false
	_apply_styles()


func _apply_styles() -> void:
	UI_STYLE.apply_shell_style(_shell, "hud_right")
	UI_STYLE.apply_label(_caption, "caption")
	UI_STYLE.apply_label(_progress_label, "alert_value")
	UI_STYLE.apply_label(_status_label, "body")
	UI_STYLE.apply_label(_claims_label, "status_line")
	UI_STYLE.apply_label(_proc_chip_label, "caption", HORIZONTAL_ALIGNMENT_RIGHT)

	UI_STYLE.apply_shell_style(_offer_shell, "live_reward")
	UI_STYLE.apply_label(_offer_title_label, "subheading")
	UI_STYLE.apply_label(_offer_body_label, "body")
	UI_STYLE.apply_label(_offer_hint_label, "hint")
	
	UI_STYLE.apply_bar_style(_offer_progress_bar, "support_ready")

	_caption.text = "PERFORMANCE"
	_caption.add_theme_font_size_override("font_size", 13)
	_progress_label.add_theme_font_size_override("font_size", 19)
	_status_label.add_theme_font_size_override("font_size", 15)
	_claims_label.add_theme_font_size_override("font_size", 13)
	_proc_chip_label.add_theme_font_size_override("font_size", 13)

	_offer_title_label.add_theme_font_size_override("font_size", 22)
	_offer_body_label.add_theme_font_size_override("font_size", 18)
	_offer_hint_label.add_theme_font_size_override("font_size", 16)


func bind_runtime(director: Node) -> void:
	_director = director
	if _director == null:
		return

	if _director.has_signal("state_changed"):
		_director.connect("state_changed", _refresh_hud)
	if _director.has_signal("offer_started"):
		_director.connect("offer_started", _on_offer_started)
	if _director.has_signal("offer_ended"):
		_director.connect("offer_ended", _hide_offer)
	if _director.has_signal("proc_feedback"):
		_director.connect("proc_feedback", _on_proc_feedback)

	_refresh_hud()


func process_tick(delta: float, song_mode: bool, run_finished: bool, awaiting_choice: bool) -> void:
	if _director == null or not is_instance_valid(_director):
		return

	if song_mode and not run_finished:
		if _director.has_method("has_active_offer") and _director.call("has_active_offer"):
			_refresh_offer(awaiting_choice)
		else:
			_offer_shell.visible = false
	else:
		_offer_shell.visible = false

	if _proc_chip_timer > 0.0:
		_proc_chip_timer = max(_proc_chip_timer - delta, 0.0)
		_proc_chip_label.visible = _proc_chip_timer > 0.0
		# Alpha is handled by tween; don't reset it here while timer is active.


func _refresh_hud() -> void:
	if _director == null or not is_instance_valid(_director):
		return

	var snapshot: Dictionary = _director.call("get_status_snapshot")
	var phase_index: int = int(snapshot.get("phase_index", -1))
	
	var active: bool = phase_index >= 0
	_shell.visible = active
	if not active:
		return

	var run_progress: float = float(snapshot.get("run_progress", 0.0))
	var run_score: int = int(snapshot.get("run_score", 0))
	var bonus_progress: float = float(snapshot.get("bonus_progress", 0.0))
	var next_threshold: float = float(snapshot.get("next_threshold", 0.0))
	var rewards_remaining: int = int(snapshot.get("rewards_remaining", 0))
	var claimed_tags: Array = snapshot.get("claimed_tags", [])
	var exhausted: bool = bool(snapshot.get("exhausted", false))
	var offer_active: bool = bool(snapshot.get("offer_active", false))
	var score_grade: String = String(snapshot.get("score_grade", "--"))

	if _progress_label != null:
		if exhausted:
			_progress_label.text = "SEALED"
			_progress_label.modulate = Color(0.7, 0.7, 0.7, 1.0)
		else:
			_progress_label.text = "%.0f / %.0f" % [run_progress, next_threshold]
			_progress_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
	
	if _status_label != null:
		if exhausted:
			_status_label.text = "Pack fed"
		else:
			_status_label.text = "%s  |  %d left%s" % [
				score_grade,
				rewards_remaining,
				" (live)" if offer_active else ""
			]

	if _claims_label != null:
		var claim_text: String = "--"
		if exhausted and rewards_remaining <= 0 and claimed_tags.is_empty():
			claim_text = "pack fed"
		elif not claimed_tags.is_empty():
			var latest_claim: String = String(claimed_tags[claimed_tags.size() - 1])
			if claimed_tags.size() > 1:
				claim_text = "%s +%d" % [latest_claim, claimed_tags.size() - 1]
			else:
				claim_text = latest_claim
		elif bonus_progress > 0.0:
			claim_text = "score %d  bonus +%.0f" % [run_score, bonus_progress]
		elif next_threshold > 0.0:
			claim_text = "score %d" % run_score
		_claims_label.text = _compact_hud_copy(claim_text, 22)


func _on_offer_started(_reward_data: Dictionary) -> void:
	_refresh_offer(false)
	_refresh_hud()


func _refresh_offer(awaiting_choice: bool) -> void:
	if _director == null or not is_instance_valid(_director):
		return
	if awaiting_choice:
		_hide_offer()
		return

	var reward_data: Dictionary = _director.call("get_active_offer")
	if reward_data.is_empty():
		_hide_offer()
		return

	var time_left: float = float(_director.call("get_active_offer_time_left"))
	var total_time: float = PERFORMANCE_REWARD_CONTENT.OFFER_DURATION
	
	_offer_shell.visible = true
	
	if _offer_title_label != null:
		_offer_title_label.text = "%s - %s" % [
			_compact_hud_copy(String(reward_data.get("title", "Reward")), 16).to_upper(),
			String(reward_data.get("tag", "MARK"))
		]
	
	if _offer_body_label != null:
		_offer_body_label.text = String(reward_data.get("summary", ""))
	
	if _offer_hint_label != null:
		_offer_hint_label.text = "AUTO-CLAIM IN %.1fs" % time_left
		
	if _offer_progress_bar != null:
		_offer_progress_bar.value = clamp(time_left / total_time, 0.0, 1.0)


func _hide_offer() -> void:
	_offer_shell.visible = false


func _on_proc_feedback(text: String, color: Color) -> void:
	if _proc_chip_label == null:
		return
	
	if _proc_tween != null:
		_proc_tween.kill()
	
	_proc_chip_label.text = text
	_proc_chip_label.modulate = color
	_proc_chip_label.modulate.a = 1.0
	_proc_chip_label.visible = true
	_proc_chip_timer = 1.8
	
	_proc_tween = create_tween()
	_proc_tween.tween_property(_proc_chip_label, "modulate:a", 0.0, 1.2).set_delay(0.6)
	_proc_tween.tween_callback(func() -> void:
		_proc_chip_label.visible = false
		_proc_chip_label.modulate.a = 1.0
	)


func _compact_hud_copy(text: String, max_len: int) -> String:
	if text.length() <= max_len:
		return text
	return text.left(max_len - 2) + ".."
