@tool
extends EditorPlugin

const CACHE_PATH := "res://scene_cache.json"

func _enter_tree() -> void:
	var fs := get_editor_interface().get_resource_filesystem()
	fs.filesystem_changed.connect(_rebuild_cache)
	_rebuild_cache()

func _exit_tree() -> void:
	var fs := get_editor_interface().get_resource_filesystem()
	fs.filesystem_changed.disconnect(_rebuild_cache)

func _rebuild_cache() -> void:
	var cache := {}
	_scan(get_editor_interface().get_resource_filesystem().get_filesystem(), cache)
	var file := FileAccess.open(CACHE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(cache))
	file.close()

func _scan(dir: EditorFileSystemDirectory, cache: Dictionary) -> void:
	for i in dir.get_subdir_count():
		_scan(dir.get_subdir(i), cache)
	for i in dir.get_file_count():
		var path := dir.get_file_path(i)
		if path.ends_with(".tscn"):
			cache[path.get_file().get_basename()] = path
