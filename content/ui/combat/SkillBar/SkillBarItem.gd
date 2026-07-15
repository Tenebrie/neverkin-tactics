extends Control
class_name SkillBarItem

@onready var hotkeyLabel: Label = $%HotkeyLabel
@onready var mainButton: Button = $Button
@onready var iconButton: TextureButton = $%TextureButton
@onready var tooltip: SkillBarItemTooltip = %SkillBarItemTooltip
@onready var infusedOverlay: Panel = %InfusedOverlay

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
		if is_node_ready():
			update()
			updateModulate()

var Transparent: bool = false
var Hotkey: InputEventKey

var isHovered: bool = false

func _ready():
	update()
	#TurnManager.Instance.CurrentPlayerActorChanged.connect(update)
	TurnManager.Instance.TurnChanged.connect(updateModulate)
	$Button.mouse_entered.connect(func(): isHovered = true; updateModulate())
	$Button.mouse_exited.connect(func(): isHovered = false; updateModulate())
	$Button.button_up.connect(updateModulate)
	$Button.button_down.connect(updateModulate)
	updateModulate()
	$Button.pressed.connect(onPortraitClick)

	Skill.SignalBus.afterCast.connect(func(_t):
		updateModulate()
	)

func onPortraitClick() -> void:
	if TrackedSkill == null or not TrackedSkill.isVisible():
		return

	if TrackedSkill.Controller.SelectedSkill == TrackedSkill:
		TrackedSkill.Controller.ScrollSkillOptions()
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
		hideSkillCosts()
		return
	%Panel.visible = false
	$%HotkeyLabel.visible = true

	if Hotkey != null:
		hotkeyLabel.text = Hotkey.as_text()
	else:
		hotkeyLabel.text = ""
	iconButton.texture_normal = TrackedSkill.definition.IconTexture
	setSkillCosts(TrackedSkill)
	await get_tree().process_frame
	tooltip.setSkill(self, TrackedSkill)

func hideSkillCosts():
	%ActionPointCost.visible = false
	%HealthPointCost.visible = false
	%ManaPointCost.visible = false
	%CooldownCost.visible = false

func setSkillCosts(skill: Skill):
	updateCostContainer(%ActionPointCost, skill.ActionPointCost, ColorUtils.Common.ActionPoint)
	updateCostContainer(%HealthPointCost, skill.HealthCost, ColorUtils.Common.Health)
	updateCostContainer(%ManaPointCost, skill.ManaCost, ColorUtils.Common.Mana)
	#%CooldownCost.visible = skill.definition.Cooldown > 0

func updateCostContainer(container: Control, cost: int, color: Color):
	if cost == 0:
		container.visible = false
		return
	container.visible = true
	while container.get_child_count() > cost:
		var child = container.get_child(0)
		container.remove_child(child)
		child.queue_free()
	while container.get_child_count() < cost:
		var point = Asset.Instantiate(SkillBarItemActionPoint)
		container.add_child(point)
	for child: SkillBarItemActionPoint in container.get_children():
		child.setColor(color)

func updateModulate() -> void:
	if TrackedSkill and not TrackedSkill.isVisible():
		visible = false
		tooltip.visible = false
		%TextureButton.visible = false
		%OverlayContainer.visible = false
		return

	visible = true

	if not TrackedSkill:
		tooltip.visible = false
		%TextureButton.visible = false
		%OverlayContainer.visible = false

		if Transparent:
			%Panel.self_modulate = Color.TRANSPARENT
			mainButton.mouse_filter = Control.MOUSE_FILTER_IGNORE
			mainButton.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
			return

		%Panel.self_modulate = Color.WHITE
		mainButton.mouse_filter = Control.MOUSE_FILTER_STOP
		mainButton.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_ENABLED
		mainButton.modulate = Color(0, 0, 0, 0.5)
		return

	%TextureButton.visible = true
	%OverlayContainer.visible = true
	infusedOverlay.visible = TrackedSkill.preparingInfuse

	%Panel.self_modulate = Color.WHITE
	mainButton.mouse_filter = Control.MOUSE_FILTER_STOP
	mainButton.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_ENABLED
	tooltip.visible = isHovered
	if isHovered:
		tooltip.updatePosition()

	if TrackedSkill.chargesMaximum <= 0:
		%ChargesLabel.visible = false
	else:
		%ChargesLabel.visible = true
		%ChargesLabel.text = "%d/%d"%[TrackedSkill.chargesLeft, TrackedSkill.chargesMaximum]

	if TrackedSkill.cooldownRemaining > 0:
		%CooldownLabel.visible = true
		%CooldownLabel.text = str(TrackedSkill.cooldownRemaining)
	else:
		%CooldownLabel.visible = false

	var isActive = TrackedSkill.Controller.SelectedSkill == TrackedSkill
	var base = Color.WHITE

	if isActive:
		base = base.blend(Color(0, 1, 0, 0.5))
	if isHovered:
		base = base.darkened(0.15)
	if mainButton.button_pressed:
		base = base.darkened(0.2)

	if not Error.AsBoolean(TrackedSkill.isCastable()):
		base = Color(0.4, 0.4, 0.4)

	mainButton.modulate = base
