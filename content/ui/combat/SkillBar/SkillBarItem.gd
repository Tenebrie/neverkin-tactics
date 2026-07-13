extends Control
class_name SkillBarItem

@onready var hotkeyLabel: Label = $%HotkeyLabel
@onready var mainButton: Button = $Button
@onready var iconButton: TextureButton = $%TextureButton
@onready var tooltip: SkillBarItemTooltip = %SkillBarItemTooltip

var TrackedSkill: Skill:
	set(value):
		if TrackedSkill != null:
			TrackedSkill.Controller.SelectedSkillChanged.disconnect(updateModulate)
			TrackedSkill.Controller.parent.actions.ActionPointsChanged.disconnect(updateModulate)
			TrackedSkill.Controller.parent.actions.MovementPointsChanged.disconnect(updateModulate)
		TrackedSkill = value
		if TrackedSkill != null:
			TrackedSkill.Controller.SelectedSkillChanged.connect(updateModulate)
			TrackedSkill.Controller.parent.actions.ActionPointsChanged.connect(updateModulate)
			TrackedSkill.Controller.parent.actions.MovementPointsChanged.connect(updateModulate)

var Transparent: bool = false
var Hotkey: InputEventKey

var isHovered: bool = false

func _ready():
	update()
	TurnManager.Instance.CurrentPlayerActorChanged.connect(update)
	TurnManager.Instance.TurnChanged.connect(updateModulate)
	$Button.mouse_entered.connect(func(): isHovered = true; updateModulate())
	$Button.mouse_exited.connect(func(): isHovered = false; updateModulate())
	$Button.button_up.connect(updateModulate)
	$Button.button_down.connect(updateModulate)
	updateModulate()
	$Button.pressed.connect(onPortraitClick)

	Skill.SignalBus.afterCast.connect(func(targets):
		if targets.sourceSkill == TrackedSkill:
			updateModulate()
	)

func onPortraitClick() -> void:
	if TrackedSkill == null or not TrackedSkill.isVisible():
		return

	if TrackedSkill.Controller.SelectedSkill == TrackedSkill:
		TrackedSkill.Controller.Select(null)
		return

	var validationResult: Variant = TrackedSkill.isCastable()
	if validationResult is Error:
		MessageLog.PrintErrorObject(validationResult)
		return

	if validationResult is bool and validationResult == false:
		return

	TrackedSkill.Controller.Select(TrackedSkill)

func _unhandled_input(event: InputEvent) -> void:
	if Hotkey != null and event.is_match(Hotkey) and not event.is_echo() and event.is_pressed():
		onPortraitClick()

func update() -> void:
	if TrackedSkill == null:
		iconButton.texture_normal = null
		$%HotkeyLabel.visible = false
		%Panel.visible = true
		setActionPointCost(0)
		return
	%Panel.visible = false
	$%HotkeyLabel.visible = true

	if Hotkey != null:
		hotkeyLabel.text = Hotkey.as_text()
	else:
		hotkeyLabel.text = ""
	iconButton.texture_normal = TrackedSkill.definition.IconTexture
	setActionPointCost(TrackedSkill.ActionPointCost)
	await get_tree().process_frame
	tooltip.setSkill(self, TrackedSkill)

func setActionPointCost(cost: int):
	var container = $%ActionPointCost
	while container.get_child_count() > cost:
		container.remove_child(container.get_child(0))
	while container.get_child_count() < cost:
		var point = Asset.Instantiate(SkillBarItemActionPoint)
		container.add_child(point)

func updateModulate() -> void:
	if TrackedSkill and not TrackedSkill.isVisible():
		visible = false
		return

	if TrackedSkill:
		tooltip.visible = isHovered
		if isHovered:
			tooltip.updatePosition()

	if TrackedSkill == null and Transparent:
		%Panel.self_modulate = Color.TRANSPARENT
		mainButton.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
		return

	mainButton.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_ENABLED
	var isActive = TrackedSkill != null and TrackedSkill.Controller.SelectedSkill == TrackedSkill
	var base = Color.WHITE if TrackedSkill != null else Color(0, 0, 0, 0.5)

	if isActive:
		base = base.blend(Color(0, 1, 0, 0.5))
	if isHovered:
		base = base.darkened(0.15)
	if mainButton.button_pressed:
		base = base.darkened(0.2)

	if TrackedSkill != null:
		if TrackedSkill.parent.actions.ActionPointsAvailable < TrackedSkill.ActionPointCost:
			base = Color(0.4, 0.4, 0.4)
		elif TrackedSkill.parent.stats.healthCurrent < TrackedSkill.HealthCost:
			base = Color(0.4, 0.4, 0.4)
		elif TrackedSkill.parent.stats.manaCurrent < TrackedSkill.ManaCost:
			base = Color(0.4, 0.4, 0.4)
		elif TrackedSkill.parent.actions.MovementAvailable < TrackedSkill.MovementRequired:
			base = Color(0.4, 0.4, 0.4)
		elif TrackedSkill.parent.isDead:
			base = Color(0.4, 0.4, 0.4)

		if not Error.AsBoolean(TrackedSkill.isCastable()):
			base = Color(0.4, 0.4, 0.4)

	mainButton.modulate = base
