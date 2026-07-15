extends MouseArea3D
class_name ActorHoverArea

@onready var parent: Actor = get_parent()

func _ready() -> void:
	mouseEnteredImmediate.connect(func():
		if parent.isDead:
			return
		Actor.Repository.Hovered.Register(parent)
		SignalBus.MouseEntered.emit(parent)
	)
	mouseExitedImmediate.connect(func():
		Actor.Repository.Hovered.Unregister(parent)
		SignalBus.MouseExited.emit(parent)
	)

var selectableOnRelease = false

func _unhandled_input(event: InputEvent) -> void:
	if event is not InputEventMouseButton button or event.button_index != MOUSE_BUTTON_LEFT:
		return
	if not isHovered:
		return
	if button.is_pressed():
		selectableOnRelease = canSelect()
	elif button.is_released():
		if selectableOnRelease and canSelect():
			var index = TurnManager.Instance.playerControlledActors.find(parent)
			if index >= 0:
				TurnManager.Instance.activatePlayerActorByHotkey(index)
		selectableOnRelease = false

func canSelect() -> bool:
	if TurnManager.Instance.activeFaction != Actor.PlayerFaction:
		return false
	var active = TurnManager.Instance.activePlayerActor
	return active == null or active.Skills.SelectedSkill == null

static var SignalBus: SignalBusImplementation = SignalBusImplementation.new()
class SignalBusImplementation:
	signal MouseEntered(actor: Actor)
	signal MouseExited(actor: Actor)
