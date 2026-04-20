extends Node

# Listens to EventBus.play_sfx and plays combat audio from CombatAudioContent.
# This keeps audio playback decoupled from the HUD/Presentation logic.

const COMBAT_AUDIO_CONTENT = preload("res://data/CombatAudioContent.gd")

func _ready() -> void:
	if not EventBus.play_sfx.is_connected(_on_play_sfx):
		EventBus.play_sfx.connect(_on_play_sfx)


func _exit_tree() -> void:
	if EventBus.play_sfx.is_connected(_on_play_sfx):
		EventBus.play_sfx.disconnect(_on_play_sfx)


func _on_play_sfx(cue_id: String) -> void:
	var sfx_path: String = COMBAT_AUDIO_CONTENT.get_sfx_path(cue_id)
	if sfx_path.is_empty() or not ResourceLoader.exists(sfx_path):
		# No asset yet for this cue, or path invalid.
		return

	var stream: AudioStream = load(sfx_path) as AudioStream
	if stream == null:
		return

	var player := AudioStreamPlayer.new()
	add_child(player)
	player.stream = stream
	player.bus = "SFX" # Assumes a standard Godot SFX bus exists.
	player.play()
	player.finished.connect(player.queue_free)
