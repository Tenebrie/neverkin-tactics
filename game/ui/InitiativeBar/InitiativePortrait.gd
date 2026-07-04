extends Control
class_name InitiativePortrait

@onready var nameLabel: Label = $%NameLabel
@onready var hotkeyLabel: Label = $%HotkeyLabel
@onready var portrait: TextureButton = $TextureButton

var TrackedActor: Actor = null
var HotkeyIndex: int = 0

var isHovered: bool = false

func _ready():
	update()
	TurnManager.Instance.CurrentActorChanged.connect(update)
	portrait.mouse_entered.connect(func(): isHovered = true; updateModulate())
	portrait.mouse_exited.connect(func(): isHovered = false; updateModulate())
	portrait.button_up.connect(updateModulate)
	portrait.button_down.connect(updateModulate)
	$TextureButton.pressed.connect(onPortraitClick)

func onPortraitClick() -> void:
	TurnManager.Instance.SelectCharacterByHotkey(HotkeyIndex)

func _unhandled_input(event: InputEvent) -> void:
	if event is not InputEventKey or not event.is_pressed():
		return

	if event.keycode == Key.KEY_F1 + HotkeyIndex:
		onPortraitClick()

func update() -> void:
	if TrackedActor == null:
		portrait.texture_normal = null
		return

	if TrackedActor.Behaviour is not ActorBehaviourPlayerControlled:
		return

	var controller = TrackedActor.Behaviour as ActorBehaviourPlayerControlled
	nameLabel.text = TrackedActor.Stats.Name
	hotkeyLabel.text = "F" + str(HotkeyIndex + 1)
	portrait.texture_normal = controller.Portrait
	portrait.self_modulate = Color.WHITE if TurnManager.Instance.CurrentActor == TrackedActor else Color(0.3, 0.3, 0.3)

func updateModulate() -> void:
	if TrackedActor == null:
		return
	var isActive := TurnManager.Instance.CurrentActor == TrackedActor
	var base := Color.WHITE if isActive else Color(0.3, 0.3, 0.3)
	if isHovered:
		if isActive:
			base = base.darkened(0.15)
		else:
			base = base.lightened(0.15)
	if portrait.button_pressed:
		base = base.darkened(0.1)

	portrait.self_modulate = base
