extends Node

# TutorialDirector v1.0 - Extracts tutorial logic from CombatScene to reduce God Object bloat.

var _tutorial_active: bool = false
var _tutorial_step: int = 0
var _quig_narrative_system: Node # Reference to the narrative system

func setup(narrative_system: Node) -> void:
	_quig_narrative_system = narrative_system
	
	# Initial check
	var level_index: int = GameState.get_run_level_count()
	if level_index == 0 and not GameState.meta_tutorial_completed:
		_start_tutorial()

func _start_tutorial() -> void:
	_tutorial_active = true
	_tutorial_step = 0
	
	# Connect to signals needed for progression
	if not EventBus.projectile_fired.is_connected(_on_projectile_fired):
		EventBus.projectile_fired.connect(_on_projectile_fired)
	if not EventBus.player_parried.is_connected(_on_tutorial_defense_step):
		EventBus.player_parried.connect(_on_tutorial_defense_step)
	if not EventBus.player_dodged.is_connected(_on_tutorial_defense_step):
		EventBus.player_dodged.connect(_on_tutorial_defense_step)
	if not EventBus.player_took_damage.is_connected(_on_tutorial_defense_step_damage):
		EventBus.player_took_damage.connect(_on_tutorial_defense_step_damage)
		
	# Beat 1: Movement (delayed slightly)
	get_tree().create_timer(1.2).timeout.connect(func():
		if _tutorial_active and _tutorial_step == 0:
			if _quig_narrative_system:
				_quig_narrative_system.trigger_tutorial_line("movement")
			_tutorial_step = 1
	)

func _on_projectile_fired(_sector: int, _enemy_id: int) -> void:
	if _tutorial_active and _tutorial_step == 1:
		if _quig_narrative_system:
			_quig_narrative_system.trigger_tutorial_line("attack")
		_tutorial_step = 2
		# Queue defense tutorial for slightly later
		get_tree().create_timer(4.5).timeout.connect(func():
			if _tutorial_active and _tutorial_step == 2:
				if _quig_narrative_system:
					_quig_narrative_system.trigger_tutorial_line("defense")
				_tutorial_step = 3
		)

func _on_tutorial_defense_step(_sector: int, _q: Variant = null, _d: Variant = null, _h: Vector2 = Vector2.ZERO) -> void:
	if _tutorial_active and _tutorial_step == 2:
		_tutorial_step = 3 # Player already figured it out

func _on_tutorial_defense_step_damage(_amount: float, _sector: int) -> void:
	if _tutorial_active and _tutorial_step == 2:
		if _quig_narrative_system:
			_quig_narrative_system.trigger_tutorial_line("defense")
		_tutorial_step = 3

func cleanup() -> void:
	if EventBus.projectile_fired.is_connected(_on_projectile_fired):
		EventBus.projectile_fired.disconnect(_on_projectile_fired)
	if EventBus.player_parried.is_connected(_on_tutorial_defense_step):
		EventBus.player_parried.disconnect(_on_tutorial_defense_step)
	if EventBus.player_dodged.is_connected(_on_tutorial_defense_step):
		EventBus.player_dodged.disconnect(_on_tutorial_defense_step)
	if EventBus.player_took_damage.is_connected(_on_tutorial_defense_step_damage):
		EventBus.player_took_damage.disconnect(_on_tutorial_defense_step_damage)
