extends Component
class_name ActorInputProvider

var CursorPosition: Vector3

func _process(_delta: float) -> void:
	if parent.faction == Actor.PlayerFaction:
		CursorPosition = ActorUtils.getMouseWorldPlanePosition(get_viewport())
