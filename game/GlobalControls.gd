extends Node

func _input(event: InputEvent) -> void:
	if (event is InputEventKey and event.keycode == Key.KEY_ESCAPE):
		get_tree().quit()

	if event is not InputEventKey key or event.is_echo() or event.is_released():
		return
	if key.keycode < KEY_KP_0 or key.keycode > KEY_KP_9 or not key.ctrl_pressed or not key.alt_pressed:
		return

	var faction = (key.keycode - KEY_KP_0) as Actor.Faction
	TurnManager.Instance.setPlayerFaction(faction)

func _process(_delta: float) -> void:
	MouseArea3D.updateHoverStates()
