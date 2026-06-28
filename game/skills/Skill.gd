@abstract extends Node3D
class_name Skill

@export var Definition: SkillDefinition

@onready var Controller: SkillController = get_parent()
@onready var Parent: Actor = Controller.parent

func _ready() -> void:
	name = Definition.Name

var ActionPointCost: int:
	get:
		return Definition.ActionPointCost

@abstract func Cast(targets: TargetData) -> void

enum TargetMode {
	Self,
	ActorSingle,
	PointCircle,
	LineFromSelf,
}

class TargetData:
	var actor: Actor
