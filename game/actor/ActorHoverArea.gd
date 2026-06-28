extends Area3D
class_name ActorHoverArea

@onready var parent: Actor = get_parent()

func _ready() -> void:
	mouse_entered.connect(func():
		Actor.Repository.Hovered.Register(parent)
	)
	mouse_exited.connect(func():
		Actor.Repository.Hovered.Unregister(parent)
	)
