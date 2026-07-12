extends Resource
class_name BuffDefinition

@export var name: String = "Unnamed"
@export_multiline var description: String

@export var alignment: Buff.Alignment
@export var iconTexture: Texture2D

func toKeyword(script: GDScript) -> KeywordDefinition:
	var keyword = KeywordDefinition.new()
	keyword.source = KeywordDefinition.Source.Buff
	keyword.name = name
	keyword.category = "Buff"
	keyword.description = description
	keyword.sourceScript = script
	# Allow using !buff to force resolution
	keyword.aliases = [name + "\\s?!buff"]
	return keyword
