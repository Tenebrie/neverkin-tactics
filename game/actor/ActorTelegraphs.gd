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
			dict[telegraph.definition] = telegraph.Targets
		return dict

func FindTelegraph(def: TelegraphDefinition) -> Telegraph:
	for telegraph in telegraphs:
		if telegraph.definition == def:
			return telegraph
	return null

func _parentReady() -> void:
	TurnManager.Instance.CurrentActorChanged.connect(func(_a, previous):
		if previous == parent and parent.faction == Actor.PlayerFaction:
			resetState()
	)
	parent.Skills.SelectedSkillChanged.connect(func(skill):
		onSkillSelected(skill)
	)

func _process(_delta: float) -> void:
	for telegraph in telegraphs:
		var target = telegraph.ParentSkill.parent.InputProvider.CursorPosition
		if telegraph.definition.Attachment == Telegraph.Attachment.Mouse:
			var updatedTarget = target
			updatedTarget.y = 1
			telegraph.global_position = updatedTarget

		telegraph.Tint = TelegraphColor.NoTarget
		for processor in telegraph.definition.Processors:
			processor.call(telegraph)

func resetState() -> void:
	for telegraph in telegraphs:
		telegraph.cleanUp()
	telegraphs = []

func onSkillSelected(skill: Skill):
	resetState()

	if skill == null:
		return

	for def in skill.definition.telegraphs:
		def.ParentSkill = skill
		def.Load(skill)
		var telegraph = instantiateTelegraph(def, skill)
		telegraph.position.y = RenderHeight.TelegraphBase
		telegraphs.push_back(telegraph)
		if def.Attachment == Telegraph.Attachment.Mouse:
			add_child(telegraph)
		elif def.Attachment == Telegraph.Attachment.Caster:
			skill.parent.add_child(telegraph)
		else:
			get_tree().root.add_child(telegraph)

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
	telegraph.definition = def
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
		if actor.collision_layer & def.collisionMask == 0:
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
		var targets = skill.parent.telegraphs.Targets
		skill.parent.telegraphs.TargetsChanged.emit(targets)
		SignalBus.TargetsChanged.emit(skill.parent, targets)
	)
	if def.Icon != null:
		var icon = Asset.Instantiate(TelegraphIcon)
		icon.SetIcon(def.Icon)
		icon.SetSize(Vector2(0.8, 0.8))
		telegraph.add_child(icon)
		icon.transparency = 1.0
		## TODO: Rewrite physics or something so that intersect happened same frame?
		skill.get_tree().physics_frame.connect(func():
			await skill.get_tree().physics_frame
			await skill.get_tree().physics_frame
			telegraph.create_tween().tween_property(icon, "transparency", 0.0, 0.1)
			telegraph.cleaningStarted.connect(func():
				telegraph.create_tween().tween_property(icon, "transparency", 1.0, 0.1)
			)
		, CONNECT_ONE_SHOT)
		icon.position.y = RenderHeight.AboveWalls - RenderHeight.TelegraphBase
	telegraph.ParentSkill = skill
	if def.ShootFromCover:
		telegraph.IgnoredObstacleGroups = PropWall.FindAllIgnoredFor(skill.parent)
	return telegraph

static var SignalBus: SignalBusImplementation = SignalBusImplementation.new()
class SignalBusImplementation:
	signal TargetsChanged(actor: Actor, targets: Array[Actor])
