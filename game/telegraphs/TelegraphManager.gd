extends Node
class_name TelegraphManager

static var Instance: TelegraphManager:
	get:
		return TelegraphManagerInstance

var CurrentSkill: Skill

var telegraphs: Array[Telegraph] = []

signal TargetsChanged(targets: Array[Actor])

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

var TargetsPerTelegraphDefinition: Dictionary[TelegraphDefinition, Array[Actor]]:
	get:
		var dict: Dictionary[TelegraphDefinition, Array[Actor]] = {}
		for telegraph in telegraphs:
			dict[telegraph.Definition] = telegraph.Targets
		return dict

func FindTelegraph(def: TelegraphDefinition) -> Telegraph:
	for telegraph in telegraphs:
		if telegraph.Definition == def:
			return telegraph
	return null

func _ready() -> void:
	TurnManager.Instance.CurrentActorChanged.connect(initialize)

func _process(_delta: float) -> void:
	var target = ActorUtils.GetMouseWorldPlanePosition(get_viewport())

	for telegraph in telegraphs:
		if telegraph.Definition.Attachment == Telegraph.Attachment.Mouse:
			var updatedTarget = target
			updatedTarget.y = 1
			telegraph.global_position = updatedTarget

		telegraph.Tint = TelegraphColor.NoTarget
		for processor in telegraph.Definition.Processors:
			processor.call(telegraph)

func initialize(actor: Actor, previous: Actor) -> void:
	resetState()
	if previous != null and previous.Skills.is_connected(previous.Skills.SelectedSkillChanged.get_name(), onSkillSelected):
		previous.Skills.SelectedSkillChanged.disconnect(onSkillSelected)
	if actor != null:
		actor.Skills.SelectedSkillChanged.connect(onSkillSelected)

func resetState() -> void:
	for telegraph in telegraphs:
		telegraph.cleanUp()
	telegraphs = []

func onSkillSelected(skill: Skill):
	resetState()

	if skill == null:
		return

	for def in skill.Definition.Telegraphs:
		def.Load(skill)
		var telegraph = instantiateTelegraph(def, skill)
		telegraph.position.y = RenderHeight.TelegraphBase
		telegraphs.push_back(telegraph)
		if def.Attachment == Telegraph.Attachment.Mouse:
			add_child(telegraph)
		elif def.Attachment == Telegraph.Attachment.Caster:
			skill.Parent.add_child(telegraph)

	CurrentSkill = skill

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
	telegraph.GeneralValidator = func() -> bool:
		if telegraph.IsLeaving:
			return false
		for validator in def.Validators:
			var result: Variant = validator.call(telegraph)
			if result is Error or result is bool and result == false:
				return false
		return true

	telegraph.TargetValidator = func(actor: Actor) -> bool:
		if telegraph.IsLeaving:
			return false
		if actor.collision_layer & CollisionLayer.SKILL_TARGETABLE == 0:
			return false
		for filter in def.TargetFilters:
			var result: Variant = filter.call(actor)
			if result is bool and result == false:
				return false
		return true
	telegraph.TargetsChanged.connect(func():
		TargetsChanged.emit(Targets)
	)
	if def.Icon != null:
		var icon = Asset.Instantiate(TelegraphIcon)
		icon.SetIcon(def.Icon)
		icon.SetSize(Vector2(0.8, 0.8))
		telegraph.add_child(icon)
		icon.position.y = RenderHeight.AboveWalls - RenderHeight.TelegraphBase
	telegraph.ParentSkill = skill
	return telegraph
