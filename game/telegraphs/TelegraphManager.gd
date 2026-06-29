extends Node
class_name TelegraphManager

static var Instance: TelegraphManager:
	get:
		return TelegraphManagerInstance

var CurrentSkill: Skill

var mouseTelegraphs: Array[BaseTelegraph] = []

var pointCircleTelegraph: BaseTelegraph
var pointCircleExclusionTelegraph: BaseTelegraph
var casterTelegraph: BaseTelegraph
var casterToLineTelegraph: BaseTelegraph

signal TargetsChanged(targets: Array[Actor], exclusionTargets: Array[Actor])

var Targets: Array[Actor]:
	get:
		if is_instance_valid(pointCircleTelegraph):
			return pointCircleTelegraph.Targets
		elif is_instance_valid(casterTelegraph):
			return casterTelegraph.Targets
		elif is_instance_valid(casterToLineTelegraph):
			return casterToLineTelegraph.Targets
		return []

var ExclusionTargets: Array[Actor]:
	get:
		if is_instance_valid(pointCircleExclusionTelegraph):
			return pointCircleExclusionTelegraph.Targets
		return []

func _ready() -> void:
	TurnManager.Instance.CurrentActorChanged.connect(initialize)

func _process(_delta: float) -> void:
	var target = ActorUtils.GetMouseWorldPlanePosition(get_viewport())

	for telegraph in mouseTelegraphs:
		var updatedTarget = updateMouseTelegraph(telegraph)
		updatedTarget.y = 0.05
		telegraph.position = updatedTarget

	if is_instance_valid(casterToLineTelegraph):
		target.y = casterToLineTelegraph.global_position.y
		casterToLineTelegraph.look_at(target)

func updateMouseTelegraph(telegraph: BaseTelegraph) -> Vector3:
	var target = ActorUtils.GetMouseWorldPlanePosition(get_viewport())
	if not is_instance_valid(telegraph):
		return target

	var currentSkill = TurnManager.Instance.CurrentActor.Skills.SelectedSkill
	if currentSkill == null:
		return target

	var targetFoundColor = EXCLUSION_NOPE_COLOR if telegraph == pointCircleExclusionTelegraph else TARGET_ACQUIRED_COLOR
	var noTargetColor = EXCLUSION_EMPTY_COLOR if telegraph == pointCircleExclusionTelegraph else NO_TARGET_COLOR

	if currentSkill.Definition.TargetingMode != Skill.TargetMode.ActorSingle \
		and telegraph.global_position.distance_to(TurnManager.Instance.CurrentActor.global_position) > \
			currentSkill.Definition.TargetingMaxRange + TurnManager.Instance.CurrentActor.PhysicalSize:
		telegraph.Tint = OUT_OF_RANGE_COLOR

	elif telegraph.Targets.size() > 0 && currentSkill.Definition.TargetingMode == Skill.TargetMode.ActorSingle:
		var targets = telegraph.Targets.slice(0)
		var validTargets = targets.filter(func(actor) -> bool:
			return Actor.Repository.Hovered.List.has(actor)
		)
		if validTargets.size() > 0:
			targets.sort_custom(func(a, b) -> bool:
				return a.global_position.distance_squared_to(target) < b.global_position.distance_squared_to(target)
			)
			telegraph.Tint = targetFoundColor
			return targets[0].global_position
		else:
			telegraph.Tint = noTargetColor
	elif telegraph.Targets.size() > 0:
		telegraph.Tint = targetFoundColor
	else:
		telegraph.Tint = noTargetColor
	return target

func initialize(actor: Actor, previous: Actor) -> void:
	resetState()
	if previous != null and previous.Skills.is_connected(previous.Skills.SelectedSkillChanged.get_name(), onSkillSelected):
		previous.Skills.SelectedSkillChanged.disconnect(onSkillSelected)
	if actor != null:
		actor.Skills.SelectedSkillChanged.connect(onSkillSelected)

func resetState() -> void:
	for telegraph in mouseTelegraphs:
		telegraph.cleanUp()
	mouseTelegraphs = []

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

	CurrentSkill = skill
	var def = skill.Definition
	var targetFilter = func(actor: Actor) -> bool:
		var currentActor = TurnManager.Instance.CurrentActor
		if currentActor == null:
			return false

		if def.TargetingMode == Skill.TargetMode.ActorSingle:
			var distanceToTarget = currentActor.global_position.distance_to(actor.global_position) - actor.PhysicalSize
			if distanceToTarget > def.TargetingMaxRange + currentActor.PhysicalSize:
				return false

		if def.TargetingMode == Skill.TargetMode.PointCircle:
			if not is_instance_valid(pointCircleTelegraph):
				return false
			var distanceFromCaster = currentActor.global_position.distance_to(pointCircleTelegraph.global_position)
			if distanceFromCaster > def.TargetingMaxRange + currentActor.PhysicalSize:
				return false

		return def.TargetingAllianceFilter.has(actor.stats.Alliance)

	var exclusionFilter = func(actor: Actor) -> bool:
		if def.TargetingMode == Skill.TargetMode.PointCircle and def.TargetingTravelAreaRequired > 0.0:
			return actor != skill.Parent
		return true

	if def.TargetingMode == Skill.TargetMode.Self:
		casterTelegraph = Asset.Instantiate(CircularTelegraph) as CircularTelegraph
		casterTelegraph.growPercentage = 1.0
		connectSignals(casterTelegraph)
		casterTelegraph.TargetValidator = targetFilter
		skill.Parent.add_child(casterTelegraph)
	elif def.TargetingMode == Skill.TargetMode.ActorSingle:
		pointCircleTelegraph = Asset.Instantiate(CircularTelegraph) as CircularTelegraph
		pointCircleTelegraph.growPercentage = 1.0
		pointCircleTelegraph.radius = 0.05
		connectSignals(pointCircleTelegraph)
		pointCircleTelegraph.TargetValidator = targetFilter
		add_child(pointCircleTelegraph)
		mouseTelegraphs.push_back(pointCircleTelegraph)
	elif def.TargetingMode == Skill.TargetMode.PointCircle:
		pointCircleTelegraph = Asset.Instantiate(CircularTelegraph) as CircularTelegraph
		pointCircleTelegraph.growPercentage = 1.0
		pointCircleTelegraph.radius = def.TargetingCircleRadius
		connectSignals(pointCircleTelegraph)
		pointCircleTelegraph.TargetValidator = targetFilter
		add_child(pointCircleTelegraph)
		mouseTelegraphs.push_back(pointCircleTelegraph)
		if def.TargetingTravelAreaRequired > 0.0:
			pointCircleExclusionTelegraph = Asset.Instantiate(CircularTelegraph) as CircularTelegraph
			pointCircleExclusionTelegraph.growPercentage = 1.0
			pointCircleExclusionTelegraph.radius = def.TargetingTravelAreaRequired
			pointCircleExclusionTelegraph.TargetValidator = exclusionFilter
			connectExclusionSignals(pointCircleExclusionTelegraph)
			add_child(pointCircleExclusionTelegraph)
			mouseTelegraphs.push_back(pointCircleExclusionTelegraph)

	elif def.TargetingMode == Skill.TargetMode.LineFromSelf:
		casterToLineTelegraph = Asset.Instantiate(RectangularTelegraph) as RectangularTelegraph
		casterToLineTelegraph.growPercentage = 1.0
		casterToLineTelegraph.width = def.TargetingLineWidth
		casterToLineTelegraph.length = def.TargetingMaxRange
		casterToLineTelegraph.lengthOrigin = RectangularTelegraph.Origin.Start
		connectSignals(casterToLineTelegraph)
		casterToLineTelegraph.TargetValidator = targetFilter
		skill.Parent.add_child(casterToLineTelegraph)

	if [Skill.TargetMode.ActorSingle, Skill.TargetMode.PointCircle].has(def.TargetingMode):
		casterTelegraph = Asset.Instantiate(CircularTelegraph) as CircularTelegraph
		casterTelegraph.growPercentage = 1.0
		casterTelegraph.radius = def.TargetingMaxRange + skill.Parent.PhysicalSize
		casterTelegraph.Tint = MAX_RANGE_COLOR
		skill.Parent.add_child(casterTelegraph)

func connectSignals(telegraph: BaseTelegraph):
	telegraph.TargetsChanged.connect(func():
		TargetsChanged.emit(Targets, ExclusionTargets)
	)
	telegraph.TargetsChanged.connect(func():
		telegraph.Tint = TARGET_ACQUIRED_COLOR if telegraph.Targets.size() > 0 else NO_TARGET_COLOR
	)
	telegraph.Tint = NO_TARGET_COLOR

func connectExclusionSignals(telegraph: BaseTelegraph):
	telegraph.TargetsChanged.connect(func():
		TargetsChanged.emit(Targets, ExclusionTargets)
	)
	telegraph.TargetsChanged.connect(func():
		telegraph.Tint = EXCLUSION_NOPE_COLOR if telegraph.Targets.size() > 0 else EXCLUSION_EMPTY_COLOR
	)
	telegraph.Tint = NO_TARGET_COLOR

const MAX_RANGE_COLOR = Color(0, 1, 1, 0.05)
const NO_TARGET_COLOR = Color(1, 1, 1, 0.5)
const TARGET_ACQUIRED_COLOR = Color(1, 0.2, 0, 0.7)
const OUT_OF_RANGE_COLOR = Color(0, 0, 1, 0.8)

const EXCLUSION_EMPTY_COLOR = Color(0, 0.5, 0, 1.0)
const EXCLUSION_NOPE_COLOR = Color(1, 0, 0, 1.0)
