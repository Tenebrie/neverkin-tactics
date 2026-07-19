extends Node

var closingTheGameAt = Time.get_ticks_msec()

func _input(event: InputEvent) -> void:
	if event is not InputEventKey key or event.is_echo() or event.is_released():
		return

	if key.keycode == Key.KEY_ESCAPE:
		if TurnManager.Instance.activePlayerActor?.Skills.SelectedSkill:
			TurnManager.Instance.activePlayerActor.Skills.Unselect()
			return

		if Time.get_ticks_msec() - closingTheGameAt < 1000:
			get_tree().quit()
		else:
			closingTheGameAt = Time.get_ticks_msec()
			MessageLog.PrintChatMessage("Press ESC again to close")

	if key.keycode < KEY_KP_0 or key.keycode > KEY_KP_9 or not key.ctrl_pressed or not key.alt_pressed:
		return

	var faction = (key.keycode - KEY_KP_0) as Actor.Faction
	TurnManager.Instance.setPlayerFaction(faction)

func _process(_delta: float) -> void:
	MouseArea3D.updateHoverStates()
