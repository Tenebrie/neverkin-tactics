extends Node3D
class_name Skill

@export var Definition: SkillDefinition

@onready var Controller: SkillController = get_parent()

func _ready() -> void:
	name = Definition.Name

var ActionPointCost: int:
	get:
		return Definition.ActionPointCost

func Cast(_targets: TargetData) -> void:
	printerr("Cast function is not implemented for " + str(get_script()))

enum TargetMode {
	Self,
	ActorClick,
}

class TargetData:
	var actor: Actor
