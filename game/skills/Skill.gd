@abstract extends Node3D
class_name Skill

signal BeforeCast(targets: TargetData)
signal OnCast(targets: TargetData)
signal AfterCast(targets: TargetData)

@export var Definition: SkillDefinition

@onready var Controller: SkillController = get_parent().get_parent()
@onready var ControlGroup: SkillController.ControlGroup:
	get: return get_parent()
@onready var Parent: Actor = Controller.Parent

func _ready() -> void:
	name = Definition.Name

var ActionPointCost: int:
	get:
		return Definition.ActionPointCost
var MovementRequired: float:
	get:
		return Definition.MovementRequired

func PerformCast(targets: TargetData) -> void:
	MessageLog.PrintActorMessage(Definition.Name, Parent)
	BeforeCast.emit(targets)
	Cast(targets)
	OnCast.emit(targets)
	AfterCast.emit(targets)

func Cast(_targets: TargetData) -> void:
	pass

func StartSequence() -> Sequencer:
	return Sequencer.Start(self)

enum TargetMode {
	Self,
	ActorSingle,
	PointCircle,
	LineFromSelf,
}

class TargetData:
	var SourceSkill: Skill
	var actor: Actor

	## Actors matching normal telegraphs
	var actors: Array[Actor]

	## World point under cursor
	var mousePoint: Vector3

	var PerTelegraph: Dictionary[TelegraphDefinition, Array[Actor]]
	var PerTelegraphIndex: Array[Array[Actor]]

	static func Collect(actor: Actor) -> Skill.TargetData:
		var targetData = Skill.TargetData.new()
		targetData.SourceSkill = actor.Skills.SelectedSkill
		if actor.Telegraphs.Targets.size() > 0:
			targetData.actor = actor.Telegraphs.Targets.get(0)
		targetData.actors = actor.Telegraphs.Targets
		targetData.mousePoint = actor.InputProvider.CursorPosition
		targetData.PerTelegraph = actor.Telegraphs.TargetsPerTelegraphDefinition
		targetData.PerTelegraphIndex = targetData.PerTelegraph.values()
		return targetData
