class_name EncounterControlsPrefs

const FILE_PATH = "user://encounter_controls.json"

static func Save(controls: EncounterControls) -> void:
	var data = {
		"arenaSize": { "x": controls.arenaSize.x, "y": controls.arenaSize.y },
		"kinRows": _serializeRows(controls.kinFactionControls.getRows()),
		"wolfpackRows": _serializeRows(controls.wolfpackFactionControls.getRows()),
	}
	var file = FileAccess.open(FILE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))

static func Reset() -> void:
	DirAccess.remove_absolute(FILE_PATH)

static func Load(controls: EncounterControls) -> void:
	if not FileAccess.file_exists(FILE_PATH):
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(FILE_PATH))
	if not data is Dictionary:
		return
	if data.get("arenaSize") is Dictionary size:
		controls.arenaSize = Vector2i(int(size.get("x", 16)), int(size.get("y", 10)))
	if data.get("kinRows") is Array kinRows:
		controls.kinFactionControls.setRows(_deserializeRows(kinRows))
	if data.get("wolfpackRows") is Array wolfpackRows:
		controls.wolfpackFactionControls.setRows(_deserializeRows(wolfpackRows))

static func _serializeRows(rows: Array[EncounterControlsActorRow]) -> Array:
	var result = []
	for row in rows:
		result.push_back({ "count": row.count, "selected": row.selected })
	return result

static func _deserializeRows(data: Array) -> Array[EncounterControlsActorRow]:
	var rows: Array[EncounterControlsActorRow] = []
	for entry in data:
		if entry is Dictionary dict:
			var row = EncounterControlsActorRow.new()
			row.count = int(dict.get("count", 1))
			row.selected = int(dict.get("selected", 0))
			rows.push_back(row)
	return rows
