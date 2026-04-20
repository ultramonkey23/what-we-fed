extends Node

var _pending_request: Dictionary = {}


func queue_request(request: Dictionary) -> void:
	_pending_request = request.duplicate(true)


func has_pending_request() -> bool:
	return not _pending_request.is_empty()


func get_pending_request() -> Dictionary:
	return _pending_request.duplicate(true)


func clear_request() -> void:
	_pending_request.clear()
