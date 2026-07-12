extends Resource
class_name KeywordDefinition

## Canonical name of the keyword
@export var name: String
## Mechanic/location/character/faction/etc.
@export var category: String
## The main description body
@export_multiline var description: String

## Other names this keyword is recognized as
@export var aliases: Array[String]
## Color to use in descriptions
@export var color: Color = Color.ORANGE

var source: Source = Source.Native
var sourceScript: GDScript = null
enum Source {
	Native,
	Buff,
	Skill,
}
