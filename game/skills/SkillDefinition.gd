@tool
extends Resource
class_name SkillDefinition

@export var Name: String = "Unnamed"
@export var IconTexture: Texture2D
@export var ActionPointCost: int = 1


@export_group("Skill Targeting", "Targeting")
@export var TargetingMode: Skill.TargetMode:
	set(value):
		TargetingMode = value
		notify_property_list_changed()
@export var TargetingMaxRange: float = 1.0
@export var TargetingAllianceFilter: Array[Actor.Alliance] = [Actor.Alliance.Player, Actor.Alliance.Neutral, Actor.Alliance.Hostile]

@export_group("Circle", "TargetingCircle")
@export var TargetingCircleRadius: float = 1.0

@export_group("Line", "TargetingLine")
@export var TargetingLineWidth: float = 0.2


func _validate_property(property: Dictionary):
	if property.name == "TargetingMaxRange" and TargetingMode == Skill.TargetMode.Self:
		property.usage &= ~PROPERTY_USAGE_EDITOR
	if property.name == "TargetingCircleRadius" and TargetingMode != Skill.TargetMode.PointCircle:
		property.usage &= ~PROPERTY_USAGE_EDITOR
	if property.name == "TargetingLineWidth" and TargetingMode != Skill.TargetMode.LineFromSelf:
		property.usage &= ~PROPERTY_USAGE_EDITOR
