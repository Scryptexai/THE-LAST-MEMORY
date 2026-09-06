class_name GameLog
extends RefCounted
## Sistem logging terpusat. Matikan `enabled` untuk build production.

static var enabled: bool = true
static var show_timestamp: bool = false


static func _prefix(level: String) -> String:
	if show_timestamp:
		var t: Dictionary = Time.get_datetime_dict_from_system()
		return "[%s %02d:%02d:%02d]" % [level, int(t.get("hour", 0)), int(t.get("minute", 0)), int(t.get("second", 0))]
	return "[%s]" % level


static func debug(msg: String) -> void:
	if enabled:
		print("%s %s" % [_prefix("DEBUG"), msg])


static func info(msg: String) -> void:
	if enabled:
		print("%s %s" % [_prefix("INFO"), msg])


static func warn(msg: String) -> void:
	push_warning(msg)
	if enabled:
		printerr("%s %s" % [_prefix("WARN"), msg])


static func error(msg: String) -> void:
	push_error(msg)
	printerr("%s %s" % [_prefix("ERROR"), msg])
