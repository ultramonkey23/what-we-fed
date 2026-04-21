extends VBoxContainer

const PERFORMANCE_REWARD_CONTENT = preload("res://data/PerformanceRewardContent.gd")
const UI_STYLE = preload("res://systems/UIStyle.gd")

var _director: Node = null
var _proc_chip_timer: float = 0.0
var _proc_tween: Tween = null
var _message_lane_blocked: bool = false

var _shell: Control = null
var _caption: Label = null
var _progress_label: Label = null
var _status_label: Label = null
var _claims_label: Label = null
var _proc_chip_label: Label = null

var _offer_shell: Control = null
var _offer_title_label: Label = null
var _offer_body_label: Label = null
var _offer_hint_label: Label = null
var _offer_progress_bar: ProgressBar = null
var _offer_creature_silhouette: ColorRect = null
var _bond_choice_label: Label = null
var _eat_choice_label: Label = null
var _ultimate_shell: Control = null
var _ultimate_label: Label = null
var _ultimate_progress_bar: ProgressBar = null


func _ready() -> void:
	_cache_nodes()
	if _shell == null:
		return
	_shell.visible = false
	if _offer_shell != null:
		_offer_shell.visible = false
	if _proc_chip_label != null:
		_proc_chip_label.visible = false
	_apply_styles()


func _cache_nodes() -> void:
	_shell = get_node_or_null("%PerformanceShell")
	if _shell == null:
		_shell = get_node_or_null("PerformancePanel")
	if _shell == null:
		_shell = get_node_or_null("PerformanceShell")

	_caption = _resolve_label(["%Caption", "PerformancePanel/PerformanceContainer/Caption"])
	_progress_label = _resolve_label(["%ProgressLabel", "%PowerLevel", "PerformancePanel/PerformanceContainer/ProgressLabel", "PerformancePanel/PerformanceContainer/PowerLevel"])
	_status_label = _resolve_label(["%StatusLabel", "PerformancePanel/PerformanceContainer/StatusLabel"])
	_claims_label = _resolve_label(["%ClaimsLabel", "%ComboDisplay", "PerformancePanel/PerformanceContainer/ClaimsLabel", "PerformancePanel/PerformanceContainer/ComboDisplay"])
	_proc_chip_label = _resolve_label(["%ProcChipLabel"])

	_offer_shell = get_node_or_null("%OfferShell")
	if _offer_shell == null:
		_offer_shell = get_node_or_null("OfferPanel")
	if _offer_shell == null:
		_offer_shell = get_node_or_null("OfferShell")

	_offer_title_label = _resolve_label(["%OfferTitleLabel", "OfferPanel/OfferContainer/OfferTitleLabel", "OfferShell/OfferContainer/OfferTitleLabel"])
	_offer_body_label = _resolve_label(["%OfferBodyLabel", "OfferPanel/OfferContainer/OfferBodyLabel", "OfferShell/OfferContainer/OfferBodyLabel"])
	_offer_hint_label = _resolve_label(["%OfferHintLabel", "OfferPanel/OfferContainer/OfferHintLabel", "OfferShell/OfferContainer/OfferHintLabel"])
	_offer_progress_bar = _resolve_progress_bar(["%OfferProgressBar", "OfferPanel/OfferProgressBar", "OfferShell/OfferProgressBar"])
	_offer_creature_silhouette = _resolve_color_rect(["OfferPanel/OfferContainer/CreatureSilhouette"])
	_bond_choice_label = _resolve_label(["OfferPanel/OfferContainer/ChoiceContainer/BondChoice"])
	_eat_choice_label = _resolve_label(["OfferPanel/OfferContainer/ChoiceContainer/EatChoice"])
	_ultimate_shell = _resolve_control(["UltimateGauge"])
	_ultimate_label = _resolve_label(["UltimateGauge/UltimateContainer/UltimateLabel"])
	_ultimate_progress_bar = _resolve_progress_bar(["UltimateGauge/UltimateContainer/UltimateProgressBar"])


func _resolve_label(paths: Array[String]) -> Label:
	for p in paths:
		var node: Node = get_node_or_null(p)
		if node is Label:
			return node as Label
	return null


func _resolve_progress_bar(paths: Array[String]) -> ProgressBar:
	for p in paths:
		var node: Node = get_node_or_null(p)
		if node is ProgressBar:
			return node as ProgressBar
	return null


func _resolve_color_rect(paths: Array[String]) -> ColorRect:
	for p in paths:
		var node: Node = get_node_or_null(p)
		if node is ColorRect:
			return node as ColorRect
	return null


func _resolve_control(paths: Array[String]) -> Control:
	for p in paths:
		var node: Node = get_node_or_null(p)
		if node is Control:
			return node as Control
	return null


func _apply_styles() -> void:
	if _shell != null:
		UI_STYLE.apply_shell_style(_shell, "mm_command")
	if _caption != null:
		UI_STYLE.apply_label(_caption, "mm_caption")
	if _progress_label != null:
		UI_STYLE.apply_label(_progress_label, "mm_monster_alert")
	if _status_label != null:
		UI_STYLE.apply_label(_status_label, "mm_body")
	if _claims_label != null:
		UI_STYLE.apply_label(_claims_label, "mm_stat_secondary")
	if _proc_chip_label != null:
		UI_STYLE.apply_label(_proc_chip_label, "mm_caption", HORIZONTAL_ALIGNMENT_RIGHT)

	if _offer_shell != null:
		UI_STYLE.apply_shell_style(_offer_shell, "mm_mutation")
	if _offer_title_label != null:
		UI_STYLE.apply_label(_offer_title_label, "mm_choice_consume")
	if _offer_body_label != null:
		UI_STYLE.apply_label(_offer_body_label, "mm_body")
	if _offer_hint_label != null:
		UI_STYLE.apply_label(_offer_hint_label, "mm_hint")
	
	if _offer_progress_bar != null:
		UI_STYLE.apply_bar_style(_offer_progress_bar, "mm_offer")
	if _offer_creature_silhouette != null:
		var silhouette_color: Color = UI_STYLE.get_manga_color("deep_violet")
		_offer_creature_silhouette.color = Color(silhouette_color.r, silhouette_color.g, silhouette_color.b, 0.78)
	if _bond_choice_label != null:
		UI_STYLE.apply_label(_bond_choice_label, "mm_choice_bond")
		_bond_choice_label.add_theme_font_size_override("font_size", 13)
	if _eat_choice_label != null:
		UI_STYLE.apply_label(_eat_choice_label, "mm_choice_consume")
		_eat_choice_label.add_theme_font_size_override("font_size", 13)
	if _ultimate_shell != null:
		UI_STYLE.apply_shell_style(_ultimate_shell, "mm_apex")
	if _ultimate_label != null:
		UI_STYLE.apply_label(_ultimate_label, "mm_monster_alert")
		_ultimate_label.add_theme_font_size_override("font_size", 12)
	if _ultimate_progress_bar != null:
		UI_STYLE.apply_bar_style(_ultimate_progress_bar, "mm_ultimate")

	if _caption != null:
		_caption.text = "PREDATION METER"
		_caption.add_theme_font_size_override("font_size", 12)
	if _progress_label != null:
		_progress_label.add_theme_font_size_override("font_size", 16)
	if _status_label != null:
		_status_label.add_theme_font_size_override("font_size", 13)
	if _claims_label != null:
		_claims_label.add_theme_font_size_override("font_size", 12)
	if _proc_chip_label != null:
		_proc_chip_label.add_theme_font_size_override("font_size", 12)

	if _offer_title_label != null:
		_offer_title_label.add_theme_font_size_override("font_size", 14)
	if _offer_body_label != null:
		_offer_body_label.add_theme_font_size_override("font_size", 12)
	if _offer_hint_label != null:
		_offer_hint_label.add_theme_font_size_override("font_size", 11)


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

	if _message_lane_blocked:
		_hide_offer()
	elif song_mode and not run_finished:
		if _director.has_method("has_active_offer") and _director.call("has_active_offer"):
			_refresh_offer(awaiting_choice)
		else:
			if _offer_shell != null:
				_offer_shell.visible = false
	else:
		if _offer_shell != null:
			_offer_shell.visible = false

	if _proc_chip_timer > 0.0:
		_proc_chip_timer = max(_proc_chip_timer - delta, 0.0)
		if _proc_chip_label != null:
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
	if _message_lane_blocked:
		_hide_offer()
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
	
	if _offer_shell != null:
		_offer_shell.visible = true
	
	if _offer_title_label != null:
		var offer_title: String = _compact_hud_copy(String(reward_data.get("title", "Reward")), 12).to_upper()
		var offer_tag: String = _compact_hud_copy(String(reward_data.get("tag", "MARK")), 6)
		_offer_title_label.text = "%s %s" % [offer_title, offer_tag]
	
	if _offer_body_label != null:
		_offer_body_label.text = _compact_hud_copy(String(reward_data.get("summary", "")), 40)
	
	if _offer_hint_label != null:
		_offer_hint_label.text = "AUTO %.1fs" % time_left
		
	if _offer_progress_bar != null:
		_offer_progress_bar.value = clamp(time_left / total_time, 0.0, 1.0)


func _hide_offer() -> void:
	if _offer_shell != null:
		_offer_shell.visible = false


func set_message_lane_blocked(blocked: bool) -> void:
	_message_lane_blocked = blocked
	if blocked:
		_hide_offer()


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
