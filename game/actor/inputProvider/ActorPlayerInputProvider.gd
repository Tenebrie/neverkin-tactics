extends ActorInputProvider
class_name ActorPlayerInputProvider

func _process(_delta: float) -> void:
	CursorPosition = ActorUtils.getMouseWorldPlanePosition(get_viewport())
