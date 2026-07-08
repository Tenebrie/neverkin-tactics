extends Area3D
class_name ActorHoverArea

@onready var parent: Actor = get_parent()

func _ready() -> void:
	mouse_entered.connect(func():
		if parent.isDestroyed:
			return
		Actor.Repository.Hovered.Register(parent)
		SignalBus.MouseEntered.emit(parent)
	)
	mouse_exited.connect(func():
		Actor.Repository.Hovered.Unregister(parent)
		SignalBus.MouseExited.emit(parent)
	)

static var SignalBus: SignalBusImplementation = SignalBusImplementation.new()
class SignalBusImplementation:
	signal MouseEntered(actor: Actor)
	signal MouseExited(actor: Actor)
