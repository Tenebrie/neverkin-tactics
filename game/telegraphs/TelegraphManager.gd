extends Node
class_name TelegraphManager

static var Instance: TelegraphManager:
	get:
		return TelegraphManagerInstance

var mouseTelegraph: BaseTelegraph
var casterTelegraph: BaseTelegraph
var casterToLineTelegraph: BaseTelegraph

signal TargetEntered(target: Actor)
signal TargetExited(target: Actor)
signal TargetsChanged(targets: Array[Actor])

var Targets: Array[Actor]:
	get:
		if is_instance_valid(mouseTelegraph):
			return mouseTelegraph.Targets
		elif is_instance_valid(casterTelegraph):
			return casterTelegraph.Targets
		elif is_instance_valid(casterToLineTelegraph):
			return casterToLineTelegraph.Targets
		return []

func _ready() -> void:
	TurnManager.Instance.CurrentActorChanged.connect(initialize)

func _process(_delta: float) -> void:
	var target = ActorUtils.GetMouseWorldPlanePosition(get_viewport())
	if is_instance_valid(mouseTelegraph) and mouseTelegraph.Targets.size() > 0:
		var currentSkill = TurnManager.Instance.CurrentActor.Skills.SelectedSkill
		if currentSkill == null:
			return
		if currentSkill.Definition.TargetingMode == Skill.TargetMode.ActorSingle:
			var targets = mouseTelegraph.Targets.slice(0)
			var validTargets = targets.filter(func(actor) -> bool:
				return Actor.Repository.Hovered.List.has(actor)
			)
			if validTargets.size() > 0:
				targets.sort_custom(func(a, b) -> bool:
					return a.global_position.distance_squared_to(target) < b.global_position.distance_squared_to(target)
				)
				target = targets[0].global_position
			else:
				mouseTelegraph.Tint = NO_TARGET_COLOR

	if is_instance_valid(mouseTelegraph):
		target.y = 0.05
		mouseTelegraph.position = target
	if is_instance_valid(casterToLineTelegraph):
		target.y = casterToLineTelegraph.global_position.y
		casterToLineTelegraph.look_at(target)

func initialize(actor: Actor, previous: Actor) -> void:
	resetState()
	if previous != null and previous.Skills.is_connected(previous.Skills.SelectedSkillChanged.get_name(), onSkillSelected):
		previous.Skills.SelectedSkillChanged.disconnect(onSkillSelected)
	if actor != null:
		actor.Skills.SelectedSkillChanged.connect(onSkillSelected)

func resetState() -> void:
	if is_instance_valid(mouseTelegraph):
		mouseTelegraph.cleanUp()
		mouseTelegraph = null
	if is_instance_valid(casterTelegraph):
		casterTelegraph.cleanUp()
		casterTelegraph = null
	if is_instance_valid(casterToLineTelegraph):
		casterToLineTelegraph.cleanUp()
		casterToLineTelegraph = null

func onSkillSelected(skill: Skill):
	resetState()

	if skill == null:
		return
	var def = skill.Definition
	var targetFilter = func(actor: Actor) -> bool:
		var currentActor = TurnManager.Instance.CurrentActor
		if currentActor == null:
			return false

		var distanceToTarget = currentActor.global_position.distance_to(actor.global_position) - actor.Definition.PhysicalSize
		return def.TargetingAllianceFilter.has(actor.stats.Alliance) and distanceToTarget <= def.TargetingMaxRange

	if def.TargetingMode == Skill.TargetMode.Self:
		casterTelegraph = Asset.Instantiate(CircularTelegraph) as CircularTelegraph
		casterTelegraph.growPercentage = 1.0
		connectSignals(casterTelegraph)
		casterTelegraph.TargetValidator = targetFilter
		skill.Parent.add_child(casterTelegraph)
	elif def.TargetingMode == Skill.TargetMode.ActorSingle:
		mouseTelegraph = Asset.Instantiate(CircularTelegraph) as CircularTelegraph
		mouseTelegraph.growPercentage = 1.0
		mouseTelegraph.radius = 0.05
		connectSignals(mouseTelegraph)
		mouseTelegraph.TargetValidator = targetFilter
		add_child(mouseTelegraph)
		casterTelegraph = Asset.Instantiate(CircularTelegraph) as CircularTelegraph
		casterTelegraph.growPercentage = 1.0
		casterTelegraph.radius = def.TargetingMaxRange
		casterTelegraph.Tint = MAX_RANGE_COLOR
		skill.Parent.add_child(casterTelegraph)
	elif def.TargetingMode == Skill.TargetMode.PointCircle:
		mouseTelegraph = Asset.Instantiate(CircularTelegraph) as CircularTelegraph
		mouseTelegraph.growPercentage = 1.0
		connectSignals(mouseTelegraph)
		mouseTelegraph.TargetValidator = targetFilter
		add_child(mouseTelegraph)
	elif def.TargetingMode == Skill.TargetMode.LineFromSelf:
		casterToLineTelegraph = Asset.Instantiate(RectangularTelegraph) as RectangularTelegraph
		casterToLineTelegraph.growPercentage = 1.0
		casterToLineTelegraph.width = def.TargetingLineWidth
		casterToLineTelegraph.length = def.TargetingMaxRange
		casterToLineTelegraph.lengthOrigin = RectangularTelegraph.Origin.Start
		connectSignals(casterToLineTelegraph)
		casterToLineTelegraph.TargetValidator = targetFilter
		skill.Parent.add_child(casterToLineTelegraph)

func connectSignals(telegraph: BaseTelegraph):
	telegraph.TargetEntered.connect(TargetEntered.emit)
	telegraph.TargetExited.connect(TargetExited.emit)
	telegraph.TargetsChanged.connect(TargetExited.emit)
	telegraph.TargetsChanged.connect(func():
		telegraph.Tint = TARGET_ACQUIRED_COLOR if telegraph.Targets.size() > 0 else NO_TARGET_COLOR
	)
	telegraph.Tint = NO_TARGET_COLOR

func disconnectSignals(telegraph: BaseTelegraph):
	telegraph.TargetEntered.disconnect(TargetEntered.emit)
	telegraph.TargetExited.disconnect(TargetExited.emit)
	telegraph.TargetsChanged.disconnect(TargetExited.emit)

const MAX_RANGE_COLOR = Color(0, 1, 1, 0.05)
const NO_TARGET_COLOR = Color(1, 1, 1, 0.5)
const TARGET_ACQUIRED_COLOR = Color(1, 0.2, 0, 0.7)
