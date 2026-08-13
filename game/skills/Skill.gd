@abstract extends Node3D
class_name Skill

signal selected
signal castCommitted()
signal beforeCast(targets: TargetData)
signal afterCast(targets: TargetData)
signal cleanUp

@export var definition: SkillDefinition

@onready var Controller: SkillController = get_parent().get_parent()
@onready var ControlGroup: SkillController.ControlGroup:
	get: return get_parent()
@onready var parent: Actor = Controller.parent

func _ready() -> void:
	if not definition:
		var scriptPath = get_script().resource_path
		var definitionPath = scriptPath.get_basename() + ".tres"
		var baseDefinition = load(definitionPath) as SkillDefinition
		var definitionObject = baseDefinition.duplicate() as SkillDefinition
		if not definitionObject:
			push_error("Missing definition: %s" % definitionPath)
		definition = definitionObject
		definition.base = baseDefinition

	if definition:
		name = definition.Name

	parent.Skills.BeforeSelectedSkillChanged.connect(func(current, previous):
		if current == self and previous != self:
			cleanUp.emit()
	)

	parent.actions.castCommitted.connect(func(skill):
		if skill == self:
			castCommitted.emit()
	)

	beforeCast.connect(func():
		if parent.Skills.SelectedSkill != self or parent.actions.isFreeRecast():
			return
		var isShiftPressed = Input.is_key_pressed(KEY_SHIFT)
		var isSkillVisible = Error.AsBoolean(isVisible())
		var isSkillCastable = Error.AsBoolean(isCastable())
		if not isShiftPressed or not isSkillVisible or not isSkillCastable:
			parent.Skills.Unselect()
	)

	TurnManager.Instance.FactionTurnEnded.connect(func(faction):
		if faction == parent.faction and cooldownRemaining > 0:
			cooldownRemaining -= 1
	)

	_prepare()

func _prepare() -> void:
	pass

func isCastable() -> Variant:
	if parent.isDead:
		return Error.new("%s is incapacitated!"%parent.definition.Name)
	if TurnManager.Instance.activeFaction != parent.faction:
		return Error.new("Can't use skills on enemy turn")
	if cooldownRemaining > 0:
		return Error.new("Cooling down")
	if parent.actions.MovementAvailable < MovementRequired:
		return Error.new("Not enough movement")
	if parent.actions.ActionPointsAvailable < ActionPointCost:
		return Error.new("Not enough AP")
	if HealthCost > 0 and parent.stats.healthCurrent <= HealthCost:
		return Error.new("Not enough health")
	if parent.stats.manaCurrent < ManaCost:
		return Error.new("Not enough mana")
	if chargesLeft < definition.ChargesCost:
		return Error.new("Not enough charges")
	return true

func isVisible() -> bool:
	return true

#region Snapshot
var _data = Storage.new()

class Storage extends SnapshotResource:
	@export var chargesUsed = 0
	@export var cooldownRemaining = 0

func createSnapshot() -> Storage:
	return _data.duplicate()

func restoreSnapshot(param: Variant):
	assert(param is Storage snapshot)
	_data = snapshot.duplicate()
#endregion

#region Infuse
signal preparingInfuseChanged
var preparingInfuse: bool:
	get:
		return preparingInfuse
	set(v):
		preparingInfuse = v
		preparingInfuseChanged.emit()

func isInfusable() -> bool:
	return false
#endregion

#region Recast
func getPrecastCount() -> int:
	return 0
func getRecastCount() -> int:
	return 0
#endregion

var HealthCost: int:
	get:
		return definition.HealthCost
var ManaCost: int:
	get:
		return definition.ManaCost
var ActionPointCost: int:
	get:
		return definition.ActionPointCost
var MovementRequired: float:
	get:
		return definition.MovementRequired
var ChargesRequired:
	get:
		return definition.ChargesCost

var activeCastCount = 0

func PerformCast(targets: TargetData) -> void:
	MessageLog.PrintActorMessage(definition.Name, parent)
	activeCastCount += 1
	SignalUtils.emitAsync([beforeCast, SignalBus.beforeCast], targets)
	await _cast(targets)
	SignalUtils.emitAsync([afterCast, SignalBus.afterCast], targets)
	activeCastCount -= 1

func _cast(_targets: TargetData) -> void:
	pass

func StartSequence() -> Sequencer:
	return Sequencer.Start(self)

#region Charges
var chargesUsed: int:
	get: return _data.chargesUsed
	set(v): _data.chargesUsed = v

var chargesLeft: int:
	get:
		return definition.ChargesMaximum - chargesUsed
	set(v):
		chargesUsed = clampi(definition.ChargesMaximum - v, 0, definition.ChargesMaximum)

var chargesMaximum:
	get:
		return definition.ChargesMaximum

func consumeCharges(count: int) -> void:
	chargesUsed = clampi(chargesUsed + count, 0, chargesMaximum)

func restoreCharges(count: int) -> void:
	chargesUsed = clampi(chargesUsed - count, 0, chargesMaximum)
#endregion

#region Cooldown
signal cooldownChanged(current: int)

var cooldownRemaining: int:
	get: return _data.cooldownRemaining
	set(v):
		_data.cooldownRemaining = v
		cooldownChanged.emit(v)

func startCooldown():
	if definition.Cooldown > 0:
		cooldownRemaining = definition.Cooldown
#endregion

enum TargetMode {
	Self,
	ActorSingle,
	PointCircle,
	LineFromSelf,
}

enum Category {
	None,
	Item,
	Innate,
	Learned,
}

class TargetData:
	var sourceSkill: Skill
	var actor: Actor

	## Actors matching normal telegraphs
	var actors: Array[Actor]
	var damageInstances: Dictionary[Actor, DamageInstance]
	var damageInstancesPerTelegraph: Dictionary[TelegraphDefinition, Dictionary[Actor, DamageInstance]]

	## World point under cursor
	var mousePoint: Vector3

	var pointPerTelegraph: Dictionary[TelegraphDefinition, Vector3]
	var endpointPerTelegraph: Dictionary[TelegraphDefinition, Vector3]
	var lengthPerTelegraph: Dictionary[TelegraphDefinition, float]
	var perTelegraph: Dictionary[TelegraphDefinition, Array[Actor]]
	var perTelegraphIndex: Array[Array[Actor]]

	var infusedCast: bool

	var castOrigin: Vector3

	static func Collect(actor: Actor) -> Skill.TargetData:
		var targetData = Skill.TargetData.new()
		targetData.sourceSkill = actor.Skills.SelectedSkill
		if actor.telegraphs.Targets.size() > 0:
			targetData.actor = actor.telegraphs.Targets.get(0)
		targetData.actors = actor.telegraphs.Targets
		targetData.mousePoint = actor.InputProvider.CursorPosition
		targetData.castOrigin = actor.global_position
		var approach = actor.castApproach.CurrentSolution()
		if approach and approach.canCast:
			targetData.castOrigin = approach.castOrigin
		for telegraph in actor.telegraphs.telegraphs:
			targetData.pointPerTelegraph[telegraph.definition] = ActorUtils.flatPositionOf(telegraph)
			if telegraph is BeamTelegraph:
				var beam = telegraph as BeamTelegraph
				targetData.endpointPerTelegraph[telegraph.definition] = beam.Endpoint()
				targetData.lengthPerTelegraph[telegraph.definition] = beam.length
		targetData.perTelegraph = actor.telegraphs.TargetsPerTelegraphDefinition
		targetData.perTelegraphIndex = targetData.perTelegraph.values()
		targetData.infusedCast = targetData.sourceSkill.preparingInfuse

		for target in actor.telegraphs.Targets:
			targetData.damageInstances[target] = DamageInstance.ForSkillCast(target, targetData)

		for telegraph in actor.telegraphs.telegraphs:
			var def = telegraph.definition
			var targets = actor.telegraphs.TargetsPerTelegraphDefinition.get(def, [])
			var dict: Dictionary[Actor, DamageInstance]
			for target in targets:
				dict.set(target, DamageInstance.ForSkillCastTelegraph(target, def, targetData))
			targetData.damageInstancesPerTelegraph.set(def, dict)

		return targetData

static var SignalBus: SignalBusImplementation = SignalBusImplementation.new()
class SignalBusImplementation extends NodeSignalBus:
	signal beforeCast(targets: Skill.TargetData)
	signal afterCast(targets: Skill.TargetData)
