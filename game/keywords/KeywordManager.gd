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
	loadKeywords()

func loadKeywords():
	var definitions: Array[KeywordDefinition] = []
	const DIR_PATH = "res://content/keywords"

	for fileName in ResourceLoader.list_directory(DIR_PATH):
		if fileName.ends_with("/"):
			continue
		if fileName.get_extension() != "tres":
			continue
		var path = DIR_PATH.path_join(fileName)
		var res = ResourceLoader.load(path) as KeywordDefinition
		if res:
			definitions.append(res)
		else:
			push_error("Failed to load or wrong type: %s" % path)

	for keyword in definitions:
		_pushKeyword(keyword.name, keyword)
		_pushKeyword(keyword.name.to_lower(), keyword)

		for alias in keyword.aliases:
			_pushKeyword(alias, keyword)
			_pushKeyword(alias.to_lower(), keyword)

	if allKeywords.is_empty():
		push_warning("No keyword definitions found in %s" % DIR_PATH)

func _pushKeyword(substring: String, definition: KeywordDefinition):
	var regex = RegEx.new()
	regex.compile("\\$(%s)\\b"%substring)

	var keyword = KeywordWithPattern.new()
	keyword.id = allKeywords.size()
	keyword.pattern = regex
	keyword.definition = definition
	allKeywords.push_back(keyword)
