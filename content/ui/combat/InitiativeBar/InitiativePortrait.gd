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
	Actor.SignalBus.ActorDestroyed.connect(update)
	portrait.mouse_entered.connect(func(): isHovered = true; updateModulate())
	portrait.mouse_exited.connect(func(): isHovered = false; updateModulate())
	portrait.button_up.connect(updateModulate)
	portrait.button_down.connect(updateModulate)
	$TextureButton.pressed.connect(onPortraitClick)

func onPortraitClick() -> void:
	TurnManager.Instance.activatePlayerActorByHotkey(HotkeyIndex)

func _unhandled_input(event: InputEvent) -> void:
	if event is not InputEventKey or not event.is_pressed():
		return

	if event.keycode == Key.KEY_F1 + HotkeyIndex:
		onPortraitClick()

func update() -> void:
	if TrackedActor == null or TrackedActor.Behaviour is not ActorBehaviour behaviour:
		portrait.texture_normal = null
		return

	nameLabel.text = TrackedActor.stats.Name
	nameLabel.label_settings = LabelSettings.new()
	nameLabel.label_settings.font_size = 14
	nameLabel.label_settings.outline_size = 2
	nameLabel.label_settings.outline_color = behaviour.PortraitColor
	nameLabel.label_settings.shadow_size = 1
	hotkeyLabel.text = "F" + str(HotkeyIndex + 1)
	portrait.texture_normal = TrackedActor.definition.AvatarTexture
	updateModulate()

func updateModulate() -> void:
	if TrackedActor == null:
		return

	var isActive := TurnManager.Instance.activePlayerActor == TrackedActor
	var base = Color.WHITE
	if TrackedActor.isDead:
		base = Color(0.7, 0.2, 0.2)
	elif isActive:
		base = Color.WHITE
	else:
		base = Color(0.3, 0.3, 0.3)

	if isHovered:
		if isActive:
			base = base.darkened(0.15)
		else:
			base = base.lightened(0.15)
	if portrait.button_pressed:
		base = base.darkened(0.1)

	portrait.self_modulate = base
