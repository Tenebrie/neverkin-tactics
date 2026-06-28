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
	if is_instance_valid(mouseTelegraph):
		var target = ActorUtils.GetMouseWorldPlanePosition(get_viewport())
		mouseTelegraph.position = target
	if is_instance_valid(casterToLineTelegraph):
		var target = ActorUtils.GetMouseWorldPlanePosition(get_viewport())
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
		return def.TargetingAllianceFilter.has(actor.stats.Alliance)

	if def.TargetingMode == Skill.TargetMode.Self:
		casterTelegraph = Asset.Instantiate(CircularTelegraph) as CircularTelegraph
		casterTelegraph.growPercentage = 1.0
		casterTelegraph.Alliance = Actor.Alliance.Player
		connectSignals(casterTelegraph)
		casterTelegraph.TargetValidator = targetFilter
		skill.Parent.add_child(casterTelegraph)
	elif def.TargetingMode == Skill.TargetMode.ActorSingle:
		mouseTelegraph = Asset.Instantiate(CircularTelegraph) as CircularTelegraph
		mouseTelegraph.growPercentage = 1.0
		mouseTelegraph.radius = 0.05
		mouseTelegraph.Alliance = Actor.Alliance.Player
		connectSignals(mouseTelegraph)
		mouseTelegraph.TargetValidator = targetFilter
		add_child(mouseTelegraph)
	elif def.TargetingMode == Skill.TargetMode.PointCircle:
		mouseTelegraph = Asset.Instantiate(CircularTelegraph) as CircularTelegraph
		mouseTelegraph.growPercentage = 1.0
		mouseTelegraph.Alliance = Actor.Alliance.Player
		connectSignals(mouseTelegraph)
		mouseTelegraph.TargetValidator = targetFilter
		add_child(mouseTelegraph)
	elif def.TargetingMode == Skill.TargetMode.LineFromSelf:
		casterToLineTelegraph = Asset.Instantiate(RectangularTelegraph) as RectangularTelegraph
		casterToLineTelegraph.growPercentage = 1.0
		casterToLineTelegraph.Alliance = Actor.Alliance.Player
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

func disconnectSignals(telegraph: BaseTelegraph):
	telegraph.TargetEntered.disconnect(TargetEntered.emit)
	telegraph.TargetExited.disconnect(TargetExited.emit)
	telegraph.TargetsChanged.disconnect(TargetExited.emit)
