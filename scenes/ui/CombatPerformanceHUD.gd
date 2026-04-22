extends Control

const PERFORMANCE_REWARD_CONTENT = preload("res://data/PerformanceRewardContent.gd")
const UI_STYLE = preload("res://systems/UIStyle.gd")

var _director: Node = null
var _proc_chip_timer: float = 0.0
var _proc_tween: Tween = null
var _pulse_tween: Tween = null
var _message_lane_blocked: bool = false
var _lean_mode: bool = false

# Core Panels
var _panel: Panel
var _offer_shell: Panel
var _ultimate_shell: Panel
var _exp_bar: ProgressBar

# Readout Labels
var _caption: Label
var _power_level: Label
var _combo_display: Label
var _status_label: Label
var _offer_title: Label
var _offer_body: Label
var _ultimate_bar: ProgressBar
var _ultimate_label: Label
var _proc_chip_label: Label

var _current_combo: int = 0
var _current_tier: String = "stirring"
var _ultimate_ready: bool = false


func _ready() -> void:
	_cache_nodes()
	
	if _panel: _panel.visible = false
	if _offer_shell: _offer_shell.visible = false
	if _ultimate_shell: _ultimate_shell.visible = true
	
	_connect_signals()
	_apply_styles()


func _cache_nodes() -> void:
	_panel = get_node_or_null("PerformancePanel")
	_offer_shell = get_node_or_null("OfferPanel")
	_ultimate_shell = get_node_or_null("UltimateGauge")
	_exp_bar = get_node_or_null("ExperienceBar")
	
	if _panel:
		_caption = _panel.get_node_or_null("PerformanceContainer/Caption")
		_power_level = _panel.get_node_or_null("PerformanceContainer/PowerLevel")
		_combo_display = _panel.get_node_or_null("PerformanceContainer/ComboDisplay")
		_status_label = _panel.get_node_or_null("PerformanceContainer/StatusLabel")
		_proc_chip_label = _panel.get_node_or_null("PerformanceContainer/ProcChipLabel")
		
	if _offer_shell:
		_offer_title = _offer_shell.get_node_or_null("OfferContainer/OfferTitleLabel")
		_offer_body = _offer_shell.get_node_or_null("OfferContainer/OfferBodyLabel")
		
	if _ultimate_shell:
		_ultimate_label = _ultimate_shell.get_node_or_null("UltimateContainer/UltimateLabel")
		_ultimate_bar = _ultimate_shell.get_node_or_null("UltimateContainer/UltimateProgressBar")


func _connect_signals() -> void:
	EventBus.combo_changed.connect(_on_combo_changed)
	EventBus.ultimate_available.connect(_on_ultimate_ready)
	EventBus.ultimate_fired.connect(_on_ultimate_fired)
	EventBus.combo_broken.connect(_on_combo_broken)
	EventBus.run_growth_changed.connect(_on_run_growth_changed)
	EventBus.song_beat_pulse.connect(_on_song_beat_pulse)


func _apply_styles() -> void:
	if _panel: UI_STYLE.apply_shell_style(_panel, "mm_command")
	if _exp_bar: UI_STYLE.apply_bar_style(_exp_bar, "mm_mutation")
	if _caption: 
		UI_STYLE.apply_label(_caption, "hud_metric_title")
		_caption.text = "POWER"
	if _power_level: UI_STYLE.apply_label(_power_level, "hud_metric_value")
	if _status_label: UI_STYLE.apply_label(_status_label, "hud_meta")
	if _combo_display: UI_STYLE.apply_label(_combo_display, "hud_meta")
	if _proc_chip_label: UI_STYLE.apply_label(_proc_chip_label, "mm_hint")
	if _power_level: _power_level.add_theme_font_size_override("font_size", 18)
	if _status_label: _status_label.add_theme_font_size_override("font_size", 13)
	if _combo_display: _combo_display.add_theme_font_size_override("font_size", 13)

	if _offer_shell: UI_STYLE.apply_shell_style(_offer_shell, "live_reward")
	if _offer_title: UI_STYLE.apply_label(_offer_title, "mm_choice_consume")
	if _offer_body: UI_STYLE.apply_label(_offer_body, "overlay_body")
	
	if _ultimate_shell: UI_STYLE.apply_shell_style(_ultimate_shell, "mm_apex")
	if _ultimate_label: 
		UI_STYLE.apply_label(_ultimate_label, "mm_monster_alert")
		_ultimate_label.text = "APEX"
	if _ultimate_bar: UI_STYLE.apply_bar_style(_ultimate_bar, "mm_ultimate")


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
	if _lean_mode:
		if _offer_shell:
			_offer_shell.visible = false
		return
	if _message_lane_blocked:
		_hide_offer()
	elif song_mode and not run_finished:
		if _director != null and _director.has_method("has_active_offer") and _director.call("has_active_offer"):
			_refresh_offer(awaiting_choice)
		elif _offer_shell:
			_offer_shell.visible = false
	elif _offer_shell:
		_offer_shell.visible = false

	if _proc_chip_timer > 0.0:
		_proc_chip_timer = max(_proc_chip_timer - delta, 0.0)


func _on_combo_changed(count: int, tier: String) -> void:
	_current_combo = count
	_current_tier = tier
	
	if _ultimate_bar:
		var progress: float = clamp(float(count) / 20.0, 0.0, 1.0)
		var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
		tween.tween_property(_ultimate_bar, "value", progress * 100.0, 0.25)
		tween.parallel().tween_property(_ultimate_bar, "modulate", UI_STYLE.get_tier_color(tier), 0.2)
	
	if count > 0:
		if _combo_display: _combo_display.text = "%dx" % count
		if _power_level:
			_power_level.text = tier.to_upper()
			_power_level.modulate = UI_STYLE.get_tier_color(tier)
	
	if count % 5 == 0 and count > 0:
		if _panel: _pulse_hud_element(_panel)


func _on_ultimate_ready() -> void:
	_ultimate_ready = true
	if _ultimate_label:
		_ultimate_label.text = "READY"
		_ultimate_label.modulate = Color(1.0, 0.8, 0.2, 1.0)
	_start_ultimate_pulse()


func _on_ultimate_fired(_power: float) -> void:
	_ultimate_ready = false
	if _ultimate_label:
		_ultimate_label.text = "APEX"
		_ultimate_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
	_stop_ultimate_pulse()
	if _ultimate_bar: _ultimate_bar.value = 0.0


func _on_combo_broken(_lost: int) -> void:
	_ultimate_ready = false
	if _ultimate_label: _ultimate_label.text = "APEX"
	if _ultimate_bar: _ultimate_bar.value = 0.0
	_stop_ultimate_pulse()


func _start_ultimate_pulse() -> void:
	if not _ultimate_shell: return
	if _pulse_tween != null:
		_pulse_tween.kill()
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_property(_ultimate_shell, "scale", Vector2(1.02, 1.05), 0.4).set_ease(Tween.EASE_IN_OUT)
	_pulse_tween.tween_property(_ultimate_shell, "scale", Vector2(1.0, 1.0), 0.4).set_ease(Tween.EASE_IN_OUT)


func _stop_ultimate_pulse() -> void:
	if _pulse_tween != null:
		_pulse_tween.kill()
	if _ultimate_shell: _ultimate_shell.scale = Vector2.ONE


func _on_song_beat_pulse(_beat_index: int, intensity: float) -> void:
	# Dramatic HUD pulse on beat, scaled by song intensity
	if _panel and _panel.visible:
		var pulse_scale: float = 1.0 + (intensity * 0.04)
		var t = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
		t.tween_property(_panel, "scale", Vector2(pulse_scale, pulse_scale), 0.05)
		t.tween_property(_panel, "scale", Vector2.ONE, 0.15)
	
	if _ultimate_shell and _ultimate_shell.visible:
		# Ultimate bar pulses more aggressively
		var pulse_h: float = 1.0 + (intensity * 0.08)
		var t = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
		t.tween_property(_ultimate_shell, "scale:y", pulse_h, 0.05)
		t.tween_property(_ultimate_shell, "scale:y", 1.0, 0.15)


func _pulse_hud_element(element: Control) -> void:
	var t = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t.tween_property(element, "scale", Vector2(1.05, 1.1), 0.1)
	t.tween_property(element, "scale", Vector2.ONE, 0.2)


func _refresh_hud() -> void:
	if _lean_mode:
		if _panel:
			_panel.visible = false
		if _offer_shell:
			_offer_shell.visible = false
		return
	if _director == null or not is_instance_valid(_director):
		return

	var snapshot: Dictionary = _director.call("get_status_snapshot")
	var phase_index: int = int(snapshot.get("phase_index", -1))
	
	var active: bool = phase_index >= 0
	if _panel: _panel.visible = active
	if not active:
		return

	var exhausted: bool = bool(snapshot.get("exhausted", false))
	var rewards_remaining: int = int(snapshot.get("rewards_remaining", 0))
	var score_grade: String = String(snapshot.get("score_grade", "--"))

	if _status_label:
		if exhausted:
			_status_label.text = "FED"
		else:
			_status_label.text = "%s %d" % [score_grade.left(3), rewards_remaining]


func _on_offer_started(_reward_data: Dictionary) -> void:
	if _lean_mode:
		_hide_offer()
		return
	_refresh_offer(false)
	_refresh_hud()


func _refresh_offer(awaiting_choice: bool) -> void:
	if _lean_mode:
		_hide_offer()
		return
	if _director == null or not is_instance_valid(_director) or awaiting_choice:
		_hide_offer()
		return

	var reward_data: Dictionary = _director.call("get_active_offer")
	if reward_data.is_empty():
		_hide_offer()
		return

	if _offer_shell: _offer_shell.visible = true
	if _offer_title: _offer_title.text = String(reward_data.get("title", "REWARD")).to_upper()
	if _offer_body: _offer_body.text = String(reward_data.get("summary", ""))


func _hide_offer() -> void:
	if _offer_shell: _offer_shell.visible = false


func set_message_lane_blocked(blocked: bool) -> void:
	_message_lane_blocked = blocked
	if blocked:
		_hide_offer()


func _on_proc_feedback(text: String, color: Color) -> void:
	if _proc_chip_label == null: return
	
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
	)


func _on_run_growth_changed(_level: int, exp: float, exp_to_next: float) -> void:
	if _exp_bar:
		var progress: float = clamp(exp / exp_to_next, 0.0, 1.0)
		var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
		tween.tween_property(_exp_bar, "value", progress * 100.0, 0.4)
