extends Component
class_name ActorTelegraphs

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

func _parentReady() -> void:
	TurnManager.Instance.CurrentActorChanged.connect(func(_a, previous):
		if previous == Parent and Parent.faction == Actor.PlayerFaction:
			resetState()
	)
	Parent.Skills.SelectedSkillChanged.connect(func(skill):
		onSkillSelected(skill)
	)

func _process(_delta: float) -> void:
	for telegraph in telegraphs:
		var target = telegraph.ParentSkill.Parent.InputProvider.CursorPosition
		if telegraph.Definition.Attachment == Telegraph.Attachment.Mouse:
			var updatedTarget = target
			updatedTarget.y = 1
			telegraph.global_position = updatedTarget

		telegraph.Tint = TelegraphColor.NoTarget
		for processor in telegraph.Definition.Processors:
			processor.call(telegraph)

func resetState() -> void:
	for telegraph in telegraphs:
		telegraph.cleanUp()
	telegraphs = []

func onSkillSelected(skill: Skill):
	resetState()

	if skill == null:
		return

	for def in skill.Definition.Telegraphs:
		def.ParentSkill = skill
		def.Load(skill)
		var telegraph = instantiateTelegraph(def, skill)
		telegraph.position.y = RenderHeight.TelegraphBase
		telegraphs.push_back(telegraph)
		if def.Attachment == Telegraph.Attachment.Mouse:
			add_child(telegraph)
		elif def.Attachment == Telegraph.Attachment.Caster:
			skill.Parent.add_child(telegraph)

	CurrentSkill = skill

static func instantiateTelegraph(def: TelegraphDefinition, skill: Skill) -> Telegraph:
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
		for group in telegraph.IgnoredObstacleGroups:
			if actor.is_in_group(group):
				return false
		for filter in def.TargetFilters:
			var result: Variant = filter.call(actor)
			if result is bool and result == false:
				return false
		return true
	telegraph.TargetsChanged.connect(func():
		var targets = skill.Parent.Telegraphs.Targets
		skill.Parent.Telegraphs.TargetsChanged.emit(targets)
		SignalBus.TargetsChanged.emit(skill.Parent, targets)
	)
	if def.Icon != null:
		var icon = Asset.Instantiate(TelegraphIcon)
		icon.SetIcon(def.Icon)
		icon.SetSize(Vector2(0.8, 0.8))
		telegraph.add_child(icon)
		icon.position.y = RenderHeight.AboveWalls - RenderHeight.TelegraphBase
	telegraph.ParentSkill = skill
	if def.ShootFromCover:
		telegraph.IgnoredObstacleGroups = PropWall.FindAllIgnoredFor(skill.Parent)
	return telegraph

static var SignalBus: SignalBusImplementation = SignalBusImplementation.new()
class SignalBusImplementation:
	signal TargetsChanged(actor: Actor, targets: Array[Actor])
