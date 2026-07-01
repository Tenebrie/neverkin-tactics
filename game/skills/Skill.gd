@abstract extends Node3D
class_name Skill

signal BeforeCast(targets: TargetData)
signal OnCast(targets: TargetData)
signal AfterCast(targets: TargetData)

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
var MovementRequired: float:
	get:
		return Definition.MovementRequired

func PerformCast(targets: TargetData) -> void:
	BeforeCast.emit(targets)
	Cast(targets)
	OnCast.emit(targets)
	AfterCast.emit(targets)

func Cast(_targets: TargetData) -> void:
	pass

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

	## World point under cursor
	var mousePoint: Vector3

	var perTelegraph: Dictionary[TelegraphDefinition, Array[Actor]]
	var perTelegraphIndex: Array[Array[Actor]]
