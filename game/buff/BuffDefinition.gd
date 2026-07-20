extends Resource
class_name BuffDefinition

@export var name: String = "Unnamed"
@export_multiline var description: String

@export var alignment: Buff.Alignment
@export var iconTexture: Texture2D

## Number of the target's turns this effect is active for, with -1 for infinite.
@export var durationTurns: int = -1
@export var stackType: Buff.StackType = Buff.StackType.Parallel

func toKeyword(script: GDScript) -> KeywordDefinition:
	var keyword = KeywordDefinition.new()
	keyword.source = KeywordDefinition.Source.Buff
	keyword.name = name
	keyword.category = "Buff"
	keyword.description = description
	keyword.sourceScript = script
	# Allow using !buff to force resolution
	keyword.aliases = [name + "!buff", name + " 1", name + " 2", name + " 3"]
	return keyword
