extends Node

var mouseTelegraph: BaseTelegraph
var casterTelegraph: BaseTelegraph
var casterToLineTelegraph: BaseTelegraph

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
	if def.TargetingMode == Skill.TargetMode.Self:
		casterTelegraph = Asset.Instantiate(CircularTelegraph) as CircularTelegraph
		skill.Parent.add_child(casterTelegraph)
		casterTelegraph.growPercentage = 1.0
		casterTelegraph.Alliance = Actor.Alliance.Player
	elif def.TargetingMode == Skill.TargetMode.ActorSingle:
		mouseTelegraph = Asset.Instantiate(CircularTelegraph) as CircularTelegraph
		add_child(mouseTelegraph)
		mouseTelegraph.growPercentage = 1.0
		mouseTelegraph.radius = 0.05
		mouseTelegraph.Alliance = Actor.Alliance.Player
	elif def.TargetingMode == Skill.TargetMode.PointCircle:
		mouseTelegraph = Asset.Instantiate(CircularTelegraph) as CircularTelegraph
		add_child(mouseTelegraph)
		mouseTelegraph.growPercentage = 1.0
		mouseTelegraph.Alliance = Actor.Alliance.Player
	elif def.TargetingMode == Skill.TargetMode.LineFromSelf:
		casterToLineTelegraph = Asset.Instantiate(RectangularTelegraph) as RectangularTelegraph
		skill.Parent.add_child(casterToLineTelegraph)
		casterToLineTelegraph.growPercentage = 1.0
		casterToLineTelegraph.Alliance = Actor.Alliance.Player
		casterToLineTelegraph.width = def.TargetingLineWidth
		casterToLineTelegraph.length = def.TargetingMaxRange
		casterToLineTelegraph.lengthOrigin = RectangularTelegraph.Origin.START
