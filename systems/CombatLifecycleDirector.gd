extends RefCounted

# CombatLifecycleDirector
# LaneManager remains the spatial registry and cleanup executor.


func resolve_enemy_defeat(
	enemy_id: int,
	status_director: StatusDirector,
	remove_enemy_spatial_callback: Callable,
	alive_count_callback: Callable,
	set_combat_running_callback: Callable,
	song_mode: bool
) -> void:
	if enemy_id == -1:
		return

	if status_director != null:
		status_director.clear_on_enemy_defeat(enemy_id)

	EventBus.emit_signal("enemy_defeated", enemy_id)

	if remove_enemy_spatial_callback.is_valid():
		remove_enemy_spatial_callback.call(enemy_id)

	if song_mode:
		return

	if alive_count_callback.is_valid() and int(alive_count_callback.call()) > 0:
		return

	if set_combat_running_callback.is_valid():
		set_combat_running_callback.call(false)
	EventBus.emit_signal("combat_ended", true)
