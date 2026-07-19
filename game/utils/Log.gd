class_name Log

enum Level { DEBUG, INFO, WARN, ERROR }

static var minLevel = Level.DEBUG

static func debug(message, category = "") -> void:
	_write(Level.DEBUG, message, category)

static func info(message, category = "") -> void:
	_write(Level.INFO, message, category)

static func warn(message, category = "") -> void:
	_write(Level.WARN, message, category)

static func error(message, category = "") -> void:
	_write(Level.ERROR, message, category)

static func _write(level: Level, message, category: String) -> void:
	if level < minLevel:
		return
	var line = _buildPrefix(level, category) + str(message)
	match level:
		Level.WARN: push_warning(line)
		Level.ERROR: push_error(line)
	print_rich(_colorize(level, line))

static func _buildPrefix(level: Level, category: String) -> String:
	var stamp = "[%s]" % Time.get_time_string_from_system()
	var lvl = "[%s]" % Level.keys()[level]
	var cat = " %s - " % category if category != "" else " "
	return "%s %s%s" % [stamp, lvl, cat]

static func _colorize(level: Level, line: String) -> String:
	var color = ["#888888", "cyan", "yellow", "red"][level]
	return "[color=%s]%s[/color]" % [color, line]
