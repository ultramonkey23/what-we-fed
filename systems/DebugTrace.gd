extends RefCounted

const TRACE_ENV_VAR: String = "WHAT_WE_FED_AGENT_TRACE"
const TRACE_DIR: String = "user://debug"
const TRACE_FILE: String = "user://debug/agent_trace.jsonl"


static func append_agent_event(run_id: String, hypothesis_id: String, location: String, message: String, data: Dictionary) -> void:
	if not _is_trace_enabled():
		return

	var payload: Dictionary = {
		"sessionId": String(OS.get_environment(TRACE_ENV_VAR)),
		"runId": run_id,
		"hypothesisId": hypothesis_id,
		"location": location,
		"message": message,
		"data": data,
		"timestamp": Time.get_unix_time_from_system() * 1000.0
	}

	var debug_dir: String = ProjectSettings.globalize_path(TRACE_DIR)
	DirAccess.make_dir_recursive_absolute(debug_dir)

	var file := FileAccess.open(TRACE_FILE, FileAccess.READ_WRITE)
	if file == null:
		file = FileAccess.open(TRACE_FILE, FileAccess.WRITE)
	if file == null:
		push_warning("DebugTrace could not open %s: %s" % [TRACE_FILE, FileAccess.get_open_error()])
		return

	file.seek_end()
	file.store_line(JSON.stringify(payload))
	file.close()


static func _is_trace_enabled() -> bool:
	if not OS.is_debug_build():
		return false
	var value: String = String(OS.get_environment(TRACE_ENV_VAR)).strip_edges().to_lower()
	return not value.is_empty() and value != "0" and value != "false" and value != "no" and value != "off"
