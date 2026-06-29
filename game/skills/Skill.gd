@abstract extends Node3D
class_name Skill

@export var Definition: SkillDefinition

@onready var Controller: SkillController = get_parent().get_parent()
@onready var ControlGroup: SkillController.ControlGroup:
	get: return get_parent()
@onready var Parent: Actor = Controller.parent

func _ready() -> void:
	name = Definition.Name

var ActionPointCost: int:
	get:
		return Definition.ActionPointCost

@abstract func Cast(targets: TargetData) -> void
func GetHealthDamage(_actor: Actor) -> int:
	return Definition.HealthDamage

enum TargetMode {
	Self,
	ActorSingle,
	PointCircle,
	LineFromSelf,
}

class TargetData:
	var actor: Actor

	## Actors matching normal telegraphs
	var actors: Array[Actor]

	## Actors matching negative telegraphs (i.e. blocking the use of a travel ability)
	var exclusionActors: Array[Actor]

	## World point under cursor
	var mousePoint: Vector3

	var isTravelAllowed: bool
