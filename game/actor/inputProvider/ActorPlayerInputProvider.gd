extends ActorInputProvider
class_name ActorPlayerInputProvider

func _input(event: InputEvent):
	if event is InputEventMouseMotion:
		CursorPosition = ActorUtils.GetMouseWorldPlanePosition(get_viewport())
