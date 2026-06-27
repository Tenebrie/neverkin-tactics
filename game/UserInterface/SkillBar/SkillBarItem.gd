extends Control
class_name SkillBarItem

@onready var hotkeyLabel: Label = $%HotkeyLabel
@onready var iconButton: TextureButton = $%TextureButton

var TrackedSkill: Skill = null
var HotkeyIndex: int = 0

var isHovered: bool = false

func _ready():
	update()
	TurnManager.Instance.CurrentActorChanged.connect(update)
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
	else:
		TrackedSkill.Controller.SelectByIndex(HotkeyIndex)
	updateModulate()

func _unhandled_input(event: InputEvent) -> void:
	if event is not InputEventKey or not event.is_pressed():
		return

	if event.keycode == Key.KEY_1 + HotkeyIndex:
		onPortraitClick()

func update() -> void:
	if TrackedSkill == null:
		iconButton.texture_normal = null
		$%HotkeyLabel.visible = false
		return
	$%HotkeyLabel.visible = true

	hotkeyLabel.text = str(HotkeyIndex + 1)
	iconButton.texture_normal = TrackedSkill.Definition.IconTexture

func updateModulate() -> void:
	var isActive := TrackedSkill != null and TrackedSkill.Controller.SelectedSkill == TrackedSkill
	var base := Color.WHITE if TrackedSkill != null else Color(0, 0, 0, 0.5)
	if isHovered:
		if isActive:
			base = base.darkened(0.15)
		else:
			base = base.darkened(0.15)
	if iconButton.button_pressed:
		base = base.darkened(0.2)

	$Panel.self_modulate = base
	iconButton.self_modulate = base
