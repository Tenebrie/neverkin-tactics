extends ActorInputProvider
class_name ActorPlayerInputProvider

func _process(_delta: float) -> void:
	CursorPosition = ActorUtils.GetMouseWorldPlanePosition(get_viewport())
