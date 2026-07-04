extends Control
class_name SkillBarItem

@onready var hotkeyLabel: Label = $%HotkeyLabel
@onready var iconButton: TextureButton = $%TextureButton

var TrackedSkill: Skill:
	set(value):
		if TrackedSkill != null:
			TrackedSkill.Controller.SelectedSkillChanged.disconnect(updateModulate)
			TrackedSkill.Controller.Parent.actions.ActionPointsChanged.disconnect(updateModulate)
			TrackedSkill.Controller.Parent.actions.MovementPointsChanged.disconnect(updateModulate)
		TrackedSkill = value
		if TrackedSkill != null:
			TrackedSkill.Controller.SelectedSkillChanged.connect(updateModulate)
			TrackedSkill.Controller.Parent.actions.ActionPointsChanged.connect(updateModulate)
			TrackedSkill.Controller.Parent.actions.MovementPointsChanged.connect(updateModulate)

var Transparent: bool = false
var Hotkey: InputEventKey

var isHovered: bool = false

func _ready():
	update()
	TurnManager.Instance.CurrentPlayerActorChanged.connect(update)
	TurnManager.Instance.TurnChanged.connect(updateModulate)
	iconButton.mouse_entered.connect(func(): isHovered = true; updateModulate())
	iconButton.mouse_exited.connect(func(): isHovered = false; updateModulate())
	iconButton.button_up.connect(updateModulate)
	iconButton.button_down.connect(updateModulate)
	updateModulate()
	iconButton.pressed.connect(onPortraitClick)

func onPortraitClick() -> void:
	if TrackedSkill == null:
		return

	if TrackedSkill.Controller.SelectedSkill == TrackedSkill:
		TrackedSkill.Controller.Select(null)
	elif TrackedSkill.Parent.actions.MovementAvailable < TrackedSkill.MovementRequired:
		MessageLog.PrintMessage("Not enough movement")
	elif TrackedSkill.Parent.actions.ActionPointsAvailable >= TrackedSkill.ActionPointCost:
		TrackedSkill.Controller.Select(TrackedSkill)
	else:
		MessageLog.PrintMessage("Not enough AP")

func _unhandled_input(event: InputEvent) -> void:
	if Hotkey != null and event.is_match(Hotkey) and not event.is_echo() and event.is_pressed():
		onPortraitClick()

func update() -> void:
	if TrackedSkill == null:
		iconButton.texture_normal = null
		$%HotkeyLabel.visible = false
		$Panel.visible = true
		setActionPointCost(0)
		return
	$Panel.visible = false
	$%HotkeyLabel.visible = true

	if Hotkey != null:
		hotkeyLabel.text = Hotkey.as_text()
	else:
		hotkeyLabel.text = ""
	iconButton.texture_normal = TrackedSkill.Definition.IconTexture
	setActionPointCost(TrackedSkill.ActionPointCost)

func setActionPointCost(cost: int):
	var container = $%ActionPointCost
	while container.get_child_count() > cost:
		container.remove_child(container.get_child(0))
	while container.get_child_count() < cost:
		var point = Asset.Instantiate(SkillBarItemActionPoint)
		container.add_child(point)

func updateModulate() -> void:
	if TrackedSkill == null and Transparent:
		$Panel.self_modulate = Color.TRANSPARENT
		$Panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		$%TextureButton.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return

	var isActive := TrackedSkill != null and TrackedSkill.Controller.SelectedSkill == TrackedSkill
	var base := Color.WHITE if TrackedSkill != null else Color(0, 0, 0, 0.5)

	if isActive:
		base = base.blend(Color(0, 1, 0, 0.5))
	if isHovered:
		base = base.darkened(0.15)
	if iconButton.button_pressed:
		base = base.darkened(0.2)

	if TrackedSkill != null:
		if TrackedSkill.Parent.actions.ActionPointsAvailable < TrackedSkill.ActionPointCost:
			base = Color(0.4, 0.4, 0.4)
		if TrackedSkill.Parent.actions.MovementAvailable < TrackedSkill.MovementRequired:
			base = Color(0.4, 0.4, 0.4)

	iconButton.self_modulate = base
