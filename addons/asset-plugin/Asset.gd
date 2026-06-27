@tool
extends Node
class_name Asset

static var _cacheRead := false
static var _scene_cache: Dictionary = {}

static func _prep_cache() -> void:
	if _cacheRead:
		return
	_cacheRead = true
	var file := FileAccess.open("res://scene_cache.json", FileAccess.READ)
	_scene_cache = JSON.parse_string(file.get_as_text())

static func Instantiate(type: GDScript) -> Node:
	_prep_cache()
	return Resolve(type).instantiate()

static func Resolve(type: GDScript) -> PackedScene:
	_prep_cache()
	var sceneName := type.get_global_name()
	assert(_scene_cache.has(sceneName), "No scene found: " + sceneName)
	return load(_scene_cache[sceneName]) as PackedScene

static func ResolveToPath(type: GDScript) -> String:
	_prep_cache()
	var sceneName := type.get_global_name()
	assert(_scene_cache.has(sceneName), "No scene found: " + sceneName)
	return _scene_cache[sceneName]
