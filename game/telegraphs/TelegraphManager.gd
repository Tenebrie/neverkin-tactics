extends Node
class_name TelegraphManager

static var Instance: TelegraphManager:
	get:
		return TelegraphManagerInstance

var CurrentSkill: Skill

var mouseTelegraphs: Array[Telegraph] = []

var pointCircleTelegraph: Telegraph
var pointCircleExclusionTelegraph: Telegraph
var casterTelegraph: Telegraph
var casterToLineTelegraph: Telegraph

var telegraphs: Array[Telegraph] = []

signal TargetsChanged(targets: Array[Actor], exclusionTargets: Array[Actor])

var Targets: Array[Actor]:
	get:
		var targets: Array[Actor] = []
		for telegraph in telegraphs:
			targets.append_array(telegraph.Targets)
		return targets

var TargetsPerTelegraph: Dictionary[Telegraph, Array[Actor]]:
	get:
		var dict: Dictionary[Telegraph, Array[Actor]] = {}
		for telegraph in telegraphs:
			dict[telegraph] = telegraph.Targets
		return dict

var ExclusionTargets: Array[Actor]:
	get:
		if is_instance_valid(pointCircleExclusionTelegraph):
			return pointCircleExclusionTelegraph.Targets
		return []

var IsPathable: bool:
	get:
		if is_instance_valid(pointCircleExclusionTelegraph):
			return pointCircleExclusionTelegraph.IsPathable()
		return false

func FindTelegraph(def: TelegraphDefinition) -> Telegraph:
	for telegraph in telegraphs:
		if telegraph.Definition == def:
			return telegraph
	return null

func _ready() -> void:
	TurnManager.Instance.CurrentActorChanged.connect(initialize)

func _process(_delta: float) -> void:
	var target = ActorUtils.GetMouseWorldPlanePosition(get_viewport())

	#for telegraph in mouseTelegraphs:
		#var updatedTarget = updateMouseTelegraph(telegraph)
		#updatedTarget.y = 0.05
		#telegraph.position = updatedTarget

	for telegraph in telegraphs:
		if telegraph.Definition.Attachment == Telegraph.Attachment.Mouse:
			var updatedTarget = updateMouseTelegraph(telegraph)
			updatedTarget.y = 0.05
			telegraph.global_position = updatedTarget

		telegraph.Tint = NO_TARGET_COLOR
		for processor in telegraph.Definition.Processors:
			processor.call(telegraph)

		#if telegraph.Definition.LookAtMouse:
			#target.y = telegraph.global_position.y
			#telegraph.look_at(target)

		#telegraph.Tint = telegraph.Definition.ColorSelector.call(telegraph)

func updateMouseTelegraph(telegraph: Telegraph) -> Vector3:
	var target = ActorUtils.GetMouseWorldPlanePosition(get_viewport())
	if not is_instance_valid(telegraph):
		return target

	var currentSkill = TurnManager.Instance.CurrentActor.Skills.SelectedSkill
	if currentSkill == null:
		return target

	#var targetFoundColor = EXCLUSION_NOPE_COLOR if telegraph == pointCircleExclusionTelegraph else TARGET_ACQUIRED_COLOR
	#var noTargetColor = EXCLUSION_EMPTY_COLOR if telegraph == pointCircleExclusionTelegraph else NO_TARGET_COLOR

	#if currentSkill.Definition.TargetingMode != Skill.TargetMode.ActorSingle \
		#and telegraph.global_position.distance_to(TurnManager.Instance.CurrentActor.global_position) > \
			#currentSkill.Definition.TargetingMaxRange + TurnManager.Instance.CurrentActor.PhysicalSize:
		#telegraph.Tint = OUT_OF_RANGE_COLOR
	#elif currentSkill.Definition.TargetingTravelAreaRequired > 0.0 \
			#and telegraph == pointCircleExclusionTelegraph \
			#and not pointCircleExclusionTelegraph.IsPathable():
		#telegraph.Tint = OBSTRUCTION_COLOR
	if telegraph.Targets.size() > 0 && currentSkill.Definition.TargetingMode == Skill.TargetMode.ActorSingle:
		var targets = telegraph.Targets.slice(0)
		var validTargets = targets.filter(func(actor) -> bool:
			return Actor.Repository.Hovered.List.has(actor)
		)
		if validTargets.size() > 0:
			targets.sort_custom(func(a, b) -> bool:
				return a.global_position.distance_squared_to(target) < b.global_position.distance_squared_to(target)
			)
			#telegraph.Tint = targetFoundColor
			return targets[0].global_position
		#else:
			#telegraph.Tint = noTargetColor
	#elif telegraph.Targets.size() > 0:
		#telegraph.Tint = targetFoundColor
	#else:
		#telegraph.Tint = noTargetColor
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

	for telegraph in telegraphs:
		telegraph.cleanUp()
	telegraphs = []

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

	for def in skill.Definition.Telegraphs:
		def.Load(skill)
		var telegraph = instantiateTelegraph(def, skill)
		telegraphs.push_back(telegraph)
		if def.Attachment == Telegraph.Attachment.Mouse:
			add_child(telegraph)
		elif def.Attachment == Telegraph.Attachment.Caster:
			skill.Parent.add_child(telegraph)

	CurrentSkill = skill
	var def = skill.Definition

	return
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

func connectSignals(telegraph: Telegraph):
	telegraph.TargetsChanged.connect(func():
		TargetsChanged.emit(Targets, ExclusionTargets)
	)
	#telegraph.TargetsChanged.connect(func():
		#telegraph.Tint = TARGET_ACQUIRED_COLOR if telegraph.Targets.size() > 0 else NO_TARGET_COLOR
	#)
	#telegraph.Tint = NO_TARGET_COLOR

func connectExclusionSignals(telegraph: Telegraph):
	telegraph.TargetsChanged.connect(func():
		TargetsChanged.emit(Targets, ExclusionTargets)
	)
	telegraph.TargetsChanged.connect(func():
		telegraph.Tint = EXCLUSION_NOPE_COLOR if telegraph.Targets.size() > 0 else EXCLUSION_EMPTY_COLOR
	)
	telegraph.Tint = NO_TARGET_COLOR

func instantiateTelegraph(def: TelegraphDefinition, skill: Skill) -> Telegraph:
	var telegraph: Telegraph

	if def.Shape == Telegraph.Shape.Circle:
		var circle = Asset.Instantiate(CircularTelegraph)
		circle.radius = def.CircleRadius
		telegraph = circle

	elif def.Shape == Telegraph.Shape.Rect:
		var rect = Asset.Instantiate(RectangularTelegraph)
		rect.width = def.RectWidth
		rect.length = def.RectLength
		rect.lengthOrigin = def.RectOrigin
		telegraph = rect

	telegraph.growPercentage = 1.0
	telegraph.Definition = def
	telegraph.TargetValidator = func(actor: Actor) -> bool:
		if telegraph.IsLeaving:
			return false
		for validator in def.Validators:
			var result: Variant = validator.call(telegraph)
			if result is Error or result is bool and result == false:
				return false
		return def.TargetFilter.call(actor)
	telegraph.TargetsChanged.connect(func():
		TargetsChanged.emit(Targets, ExclusionTargets)
	)
	telegraph.ParentSkill = skill
	return telegraph

const MAX_RANGE_COLOR = Color(0, 1, 1, 0.05)
const NO_TARGET_COLOR = Color(1, 1, 1, 0.5)
const TARGET_ACQUIRED_COLOR = Color(1, 0.2, 0, 0.7)
const OUT_OF_RANGE_COLOR = Color(0, 0, 1, 0.8)

const EXCLUSION_EMPTY_COLOR = Color(0, 0.5, 0, 1.0)
const EXCLUSION_NOPE_COLOR = Color(1, 0, 0, 1.0)

const OBSTRUCTION_COLOR = Color(0, 0.25, 1, 0.8)
