extends Node

func _input(event: InputEvent) -> void:
	if (event is InputEventKey and event.keycode == Key.KEY_ESCAPE):
		get_tree().quit()
