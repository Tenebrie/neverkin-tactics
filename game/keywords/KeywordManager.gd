extends Node
class_name KeywordManager

static var Instance: KeywordManager:
	get:
		return KeywordManagerInstance

class KeywordWithPattern:
	var id: int
	var pattern: RegEx
	var definition: KeywordDefinition

var allKeywords: Array[KeywordWithPattern] = []

func _enter_tree() -> void:
	var timer = PerformanceUtils.startMeasure("[init] Loading keywords")

	_loadKeywords("res://content/keywords")
	_loadResources("res://content/buffs")
	_loadResources("res://content/actors")
	_loadResources("res://content/skills")

	timer.endMeasure()

class ResourcePair:
	var scriptPath: String
	var definitionPath: String
	var scriptRef: GDScript
	var definitionRef: Resource

func _collectResources(dirPath: String, results: Array):
	for fileName in ResourceLoader.list_directory(dirPath):
		if fileName.ends_with("/"):
			_collectResources(dirPath.path_join(fileName.trim_suffix("/")), results)
			continue
		if fileName.get_extension() != "tres":
			continue
		var path = dirPath.path_join(fileName)
		var res = ResourceLoader.load(path)
		if res:
			results.append(res)
		else:
			push_error("Failed to load: %s" % path)

func _collectResourcePairs(dirPath: String, results: Array[ResourcePair]):
	var resourcePairs: Dictionary[String, ResourcePair]

	for fileName in ResourceLoader.list_directory(dirPath):
		if fileName.ends_with("/"):
			_collectResourcePairs(dirPath.path_join(fileName.trim_suffix("/")), results)
			continue
		if fileName.get_extension() != "tres" and fileName.get_extension() != "gd":
			continue
		var key = dirPath.path_join(fileName.trim_suffix(".gd").trim_suffix(".tres"))
		var pair = resourcePairs.get_or_add(key, ResourcePair.new()) as ResourcePair
		if fileName.get_extension() == "gd":
			pair.scriptPath = key + ".gd"
		elif fileName.get_extension() == "tres":
			pair.definitionPath = key + ".tres"

	for pair: ResourcePair in resourcePairs.values():
		if not pair.scriptPath or not pair.definitionPath:
			continue
		pair.scriptRef = ResourceLoader.load(pair.scriptPath)
		pair.definitionRef = ResourceLoader.load(pair.definitionPath)
		results.push_back(pair)

func _registerFrom(definition: Resource, script: GDScript):
	if definition is KeywordDefinition keyword:
		_registerKeyword(keyword)
	elif definition is BuffDefinition buff:
		_registerKeyword(buff.toKeyword(script))
	elif definition is SkillDefinition skill:
		_registerKeyword(skill.toKeyword(script))

func _loadKeywords(dirPath: String):
	var definitions: Array = []
	_collectResources(dirPath, definitions)
	for resource in definitions:
		_registerFrom(resource, null)

func _loadResources(dirPath: String):
	var pairs: Array[ResourcePair] = []
	_collectResourcePairs(dirPath, pairs)
	for pair in pairs:
		_registerFrom(pair.definitionRef, pair.scriptRef)

func _registerKeyword(keyword: KeywordDefinition):
	_pushKeyword(keyword.name, keyword)
	_pushKeyword(keyword.name.to_lower(), keyword)

	for alias in keyword.aliases:
		_pushKeyword(alias, keyword)
		_pushKeyword(alias.to_lower(), keyword)

func _pushKeyword(substring: String, definition: KeywordDefinition):
	var regex = RegEx.new()
	regex.compile("\\$(?|\\{(%s)\\}|(%s)\\b)" % [substring, substring])

	var keyword = KeywordWithPattern.new()
	keyword.id = allKeywords.size()
	keyword.pattern = regex
	keyword.definition = definition
	allKeywords.push_back(keyword)
