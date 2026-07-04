extends Area3D
class_name ActorHoverArea

@onready var Parent: Actor = get_parent()

func _ready() -> void:
	mouse_entered.connect(func():
		Actor.Repository.Hovered.Register(Parent)
		SignalBus.MouseEntered.emit(Parent)
	)
	mouse_exited.connect(func():
		Actor.Repository.Hovered.Unregister(Parent)
		SignalBus.MouseExited.emit(Parent)
	)

static var SignalBus: SignalBusImplementation = SignalBusImplementation.new()
class SignalBusImplementation:
	signal MouseEntered(actor: Actor)
	signal MouseExited(actor: Actor)
