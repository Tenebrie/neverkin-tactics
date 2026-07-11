extends ParadoxTooltip
class_name ActorHoverInfo

@onready var panelContainer: PanelContainer = $PanelContainer
@onready var nameLabel: Label = %NameLabel
@onready var factionLabel: ParadoxTextLabel = %FactionLabel
@onready var healthLabel: HLabeledValueContainer = %HealthLabel
@onready var threatLabel: ParadoxTextLabel = %ThreatLabel
@onready var movementSpeedLabel: HLabeledValueContainer = %MovementSpeedLabel

@onready var npcBehaviourSection: Control = %NPCBehaviourSection
@onready var focusTargetLabel: Label = %FocusTargetLabel
@onready var focusTargetValue: Label = %FocusTargetValue
@onready var targetReasonContainer: VBoxContainer = %TargetReasonContainer

const REASON_INDENT: int = 16
const SECTION_HEADER_COLOR: Color = Color(0.65, 0.65, 0.72)

var trackedActor: Actor
static var GloballyVisible = true

func _ready() -> void:
	super._ready()
	ActorHoverArea.SignalBus.MouseEntered.connect(func(actor):
		if TurnManager.Instance.activePlayerActor and TurnManager.Instance.activePlayerActor.Skills.SelectedSkill != null:
			return
		loadActorData(actor)
	)
	ActorHoverArea.SignalBus.MouseExited.connect(func(actor):
		if actor == trackedActor:
			trackedActor = null
	)

func _process(delta: float):
	if isLocked:
		super._process(delta)
		return

	if TurnManager.Instance.activePlayerActor and TurnManager.Instance.activePlayerActor.Skills.SelectedSkill != null or not GloballyVisible:
		visible = false
		trackedActor = null
	elif not trackedActor:
		visible = false

	super._process(delta)

func _input(event: InputEvent):
	if not trackedActor:
		return
	var isMouseButton = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT
	var isModifierKey = event is InputEventKey and (event.keycode == KEY_SHIFT or event.keycode == KEY_ALT)
	if isMouseButton or isModifierKey:
		renderSectionVisibility()
		if trackedActor.Behaviour is ActorBehaviourWorldControlled behaviour:
			renderBehaviourSection(behaviour)
			resizeToContent()
	super._input(event)

func loadActorData(actor: Actor):
	if actor == trackedActor:
		return

	trackedActor = actor
	var stylebox = panelContainer.get_theme_stylebox("panel") as StyleBoxFlat
	stylebox.corner_radius_top_left = 0
	stylebox.corner_radius_top_right = 0
	stylebox.corner_radius_bottom_left = 0
	stylebox.corner_radius_bottom_right = 0
	var tooltipOpacity = 0.95
	match(actor.Stats.Faction):
		Actor.PlayerFaction: stylebox.bg_color = Color(0.01, 0.15, 0.01, tooltipOpacity)
		Actor.Faction.CityThugs: stylebox.bg_color = Color(0.15, 0.01, 0.01, tooltipOpacity)
		Actor.Faction.Algae: stylebox.bg_color = Color(0.01, 0.01, 0.15, tooltipOpacity)
		_: stylebox.bg_color = Color(0.01, 0.01, 0.1, tooltipOpacity)
	panelContainer.add_theme_stylebox_override("panel", stylebox)

	nameLabel.text = actor.definition.Name
	factionLabel.text = ActorUtils.getFactionName(actor.Stats.Faction)
	factionLabel.add_theme_color_override("default_color", ActorUtils.getFactionColor(actor.Stats.Faction))
	healthLabel.text = "%d / %d"%[actor.Stats.HealthCurrent, actor.Stats.HealthMaximum]
	threatLabel.text = ActorUtils.getThreatLevelName(actor.Stats.ThreatCurrent)
	threatLabel.add_theme_color_override("default_color", ActorUtils.getThreatLevelColor(actor.Stats.ThreatCurrent))
	movementSpeedLabel.text = "%.1f m/a" % actor.movementSpeedPerAction

	renderSectionVisibility()
	if actor.Behaviour is ActorBehaviourWorldControlled behaviour:
		npcBehaviourSection.visible = true
		renderBehaviourSection(behaviour)
	else:
		npcBehaviourSection.visible = false

	resizeToContent()
	visible = not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)

func renderSectionVisibility() -> void:
	if not trackedActor:
		return

	visible = not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	healthLabel.visible = Input.is_key_pressed(KEY_ALT)
	movementSpeedLabel.visible = Input.is_key_pressed(KEY_ALT) and trackedActor.movementSpeedPerAction > 0
	%AltToSeeMoreLabel.visible = not Input.is_key_pressed(KEY_ALT)

func renderBehaviourSection(behaviour: ActorBehaviourWorldControlled) -> void:
	clearContainer(targetReasonContainer)
	focusTargetLabel.get_parent().visible = false

	behaviour.updateRanking()
	var ranking = behaviour.Ranking

	if not behaviour.FocusedTarget:
		addSectionHeader("Regrouping")
		return

	addSectionHeader("Threats")
	for i in ranking.size():
		var ranked = ranking[i]
		addTargetRow(ranked.Target, ranked.Value.Total, behaviour, i)
		addSortedReasons(ranked.Value.Highlights)

func addSectionHeader(text: String) -> void:
	var label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", SECTION_HEADER_COLOR)
	targetReasonContainer.add_child(label)

func addSeparator() -> void:
	var sep = HSeparator.new()
	targetReasonContainer.add_child(sep)

func addTargetRow(actor: Actor, total: float, behaviour: ActorBehaviourWorldControlled, index: int) -> void:
	var row = HBoxContainer.new()
	var rowIndexLabel = Label.new()
	rowIndexLabel.text = str(index + 1) + "."
	row.add_child(rowIndexLabel)
	var rowNameLabel = Label.new()
	rowNameLabel.text = actor.definition.Name
	rowNameLabel.add_theme_color_override("font_color", ActorUtils.getFactionColor(actor.Stats.Faction))
	row.add_child(rowNameLabel)
	if behaviour.FocusedTarget == actor:
		var icon = TextureRect.new()
		icon.texture = preload("res://assets/icons/eye-target-64.svg")
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH
		icon.self_modulate = Color("f34e4a")
		row.add_child(icon)
	if Input.is_key_pressed(KEY_SHIFT):
		var value = Label.new()
		value.text = "+%d" % total
		value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(value)
	targetReasonContainer.add_child(row)

func addSortedReasons(dict: Dictionary) -> void:
	if not Input.is_key_pressed(KEY_ALT):
		return
	var keys = dict.keys()
	keys.sort_custom(func(a, b): return dict[a] > dict[b])
	for reason in keys:
		var wrapper = MarginContainer.new()
		wrapper.add_theme_constant_override("margin_left", REASON_INDENT)
		var line = Asset.Instantiate(ActorHoverInfoTargetReason)
		line.TargetReason = reason
		if Input.is_key_pressed(KEY_SHIFT):
			line.TargetValue = dict[reason]
		wrapper.add_child(line)
		targetReasonContainer.add_child(wrapper)

func clearContainer(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
