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

var FilteredOnlyTargets: Array[Actor]:
	get:
		var targets: Array[Actor] = []
		for telegraph in telegraphs:
			targets.append_array(telegraph.FilteredOnlyTargets)
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
	parent.Skills.SelectedSkillChanged.connect(onSkillSelected)
	parent.Skills.SelectedSkillRecast.connect(onSkillSelected)

var IsFrozen = false
var frozenPositions: Dictionary[Telegraph, Vector3] = {}

func Freeze() -> void:
	IsFrozen = true
	frozenPositions = {}
	for telegraph in telegraphs:
		frozenPositions[telegraph] = telegraph.global_position

func Unfreeze() -> void:
	IsFrozen = false
	frozenPositions = {}

var lastUpdateAt = 0
var lastMousePosition = Vector2.ZERO
var lastCasterPosition = Vector3.ZERO
func _process(_delta: float) -> void:
	if IsFrozen:
		for telegraph in telegraphs:
			if frozenPositions.has(telegraph):
				telegraph.global_position = frozenPositions[telegraph]
		return

	var currentTime = Time.get_ticks_msec()
	var currentMouse = get_viewport().get_mouse_position()
	var currentCaster = parent.global_position
	if currentTime - lastUpdateAt < 16 and currentMouse.distance_to(lastMousePosition) < 1 and currentCaster.distance_to(lastCasterPosition) < 0.05:
		return

	lastUpdateAt = currentTime
	lastMousePosition = currentMouse
	lastCasterPosition = currentCaster

	for telegraph in telegraphs:
		var target = telegraph.ParentSkill.parent.InputProvider.CursorPosition
		if telegraph.definition.Attachment == Telegraph.Attachment.Mouse:
			var updatedTarget = target
			updatedTarget.y = 1
			telegraph.global_position = updatedTarget
		elif telegraph.definition.Attachment == Telegraph.Attachment.Caster:
			var offset = telegraph.ParentSkill.parent.castApproach.CastOffset
			telegraph.position = Vector3(offset.x, telegraph.position.y, offset.z)

		if telegraph.definition.DisabledSelector.call():
			telegraph.Tint = Color.TRANSPARENT
		else:
			telegraph.Tint = TelegraphColor.NoTarget
			telegraph.SelfTint = Color.WHITE
		#if telegraph.ParentSkill.preparingInfuse:
			#telegraph.Tint = TelegraphColor.NoTargetInfused

	for telegraph in telegraphs:
		if telegraph.definition.DisabledSelector.call():
			telegraph.Tint = Color.TRANSPARENT
			continue

		for processor in telegraph.definition.Processors:
			processor.call(telegraph)
		telegraph.pollTargets()
		for processor in telegraph.definition.PostProcessors:
			processor.call(telegraph)

func resetState() -> void:
	Unfreeze()
	for telegraph in telegraphs:
		telegraph.cleanUp()
	telegraphs = []
	lastUpdateAt = 0

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

	elif def.Shape == Telegraph.Shape.Capsule:
		var capsule = Asset.Instantiate(CapsuleTelegraph)
		capsule.width = def.RectWidth
		capsule.length = def.RectLength
		capsule.lengthOrigin = def.RectOrigin
		telegraph = capsule

	telegraph.growPercentage = def.fillFraction
	telegraph.definition = def
	telegraph.GeneralValidator = func() -> bool:
		if telegraph.IsLeaving:
			return false
		if telegraph.definition.DisabledSelector.call():
			return true
		for validator in def.Validators:
			var result: Variant = validator.call(telegraph)
			if result is Error or result is bool and result == false:
				return false
		return true

	telegraph.TargetValidator = func(actor: Actor) -> bool:
		if telegraph.IsLeaving:
			return false
		if telegraph.definition.DisabledSelector.call():
			return true
		if actor.collision_layer & def.collisionMask == 0:
			return false
		for group in telegraph.IgnoredObstacleGroups:
			if actor.is_in_group(group):
				return false
		for filter in def.TargetFilters:
			var result: Variant = filter.call(actor, telegraph)
			if result is bool and result == false:
				return false
		return true
	telegraph.TargetsChanged.connect(func():
		var targets = skill.parent.telegraphs.Targets
		skill.parent.telegraphs.TargetsChanged.emit(targets)
		SignalBus.TargetsChanged.emit(skill.parent, targets)
	)
	if def.TextMessage != null:
		var label = Asset.Instantiate(TelegraphText)
		label.text = def.TextMessage
		telegraph.childText = label
		telegraph.cleaningStarted.connect(func():
			label.queue_free()
		)
		telegraph.add_child(label)
	if def.Icon != null:
		var icon = Asset.Instantiate(TelegraphIcon)
		icon.SetIcon(def.Icon)
		icon.SetSize(Vector2(0.8, 0.8))
		telegraph.add_child(icon)
		telegraph.childIcon = icon
		icon.transparency = 1.0
		skill.get_tree().physics_frame.connect(func():
			telegraph.create_tween().tween_property(icon, "transparency", 0.0, 0.1)
			telegraph.cleaningStarted.connect(func():
				telegraph.create_tween().tween_property(icon, "transparency", 1.0, 0.1)
			)
		, CONNECT_ONE_SHOT)
		icon.position.y = RenderHeight.AboveWalls - RenderHeight.TelegraphBase
	telegraph.ParentSkill = skill
	if def.ShootFromCover:
		var shootOrigin = def.ShootFromCoverOrigin if def.ShootFromCoverOrigin.length_squared() > 0 else skill.parent.global_position
		telegraph.IgnoredObstacleGroups = PropWall.FindAllIgnoredFor(shootOrigin, skill.parent.physicalSize)
	return telegraph

static var SignalBus: SignalBusImplementation = SignalBusImplementation.new()
class SignalBusImplementation:
	signal TargetsChanged(actor: Actor, targets: Array[Actor])
