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
	if not Definition:
		var scriptPath = get_script().resource_path
		var definitionPath = scriptPath.get_basename() + ".tres"
		var definitionObject = load(definitionPath).duplicate() as SkillDefinition
		if not definitionObject:
			push_error("Missing definition: %s" % definitionPath)
		Definition = definitionObject

	if Definition:
		name = Definition.Name
	_prepare()

func _prepare() -> void:
	pass

var ActionPointCost: int:
	get:
		return Definition.ActionPointCost
var MovementRequired: float:
	get:
		return Definition.MovementRequired

func PerformCast(targets: TargetData) -> void:
	MessageLog.PrintActorMessage(Definition.Name, Parent)
	BeforeCast.emit(targets)
	_cast(targets)
	OnCast.emit(targets)
	AfterCast.emit(targets)

func _cast(_targets: TargetData) -> void:
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
	var sourceSkill: Skill
	var actor: Actor

	## Actors matching normal telegraphs
	var actors: Array[Actor]

	## World point under cursor
	var mousePoint: Vector3

	var pointPerTelegraph: Dictionary[TelegraphDefinition, Vector3]
	var perTelegraph: Dictionary[TelegraphDefinition, Array[Actor]]
	var perTelegraphIndex: Array[Array[Actor]]

	static func Collect(actor: Actor) -> Skill.TargetData:
		var targetData = Skill.TargetData.new()
		targetData.sourceSkill = actor.Skills.SelectedSkill
		if actor.Telegraphs.Targets.size() > 0:
			targetData.actor = actor.Telegraphs.Targets.get(0)
		targetData.actors = actor.Telegraphs.Targets
		targetData.mousePoint = actor.InputProvider.CursorPosition
		for telegraph in actor.Telegraphs.telegraphs:
			targetData.pointPerTelegraph[telegraph.Definition] = ActorUtils.flatPositionOf(telegraph)
		targetData.perTelegraph = actor.Telegraphs.TargetsPerTelegraphDefinition
		targetData.perTelegraphIndex = targetData.perTelegraph.values()
		return targetData
