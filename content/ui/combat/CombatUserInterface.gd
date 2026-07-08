extends Control

@onready var cursor: CursorUserInterface = $CursorUI
@onready var initiativeBar: InitiativeBarUI = $InitiativeBar
@onready var skillBar: SkillBar = $SkillBar
@onready var actorHoverInfo: Control = $ActorHoverInfoContainer

func _unhandled_input(event: InputEvent) -> void:
	if event is not InputEventKey or not event.is_pressed() or event.is_echo() or event.ctrl_pressed:
		return

	var key = event.keycode
	if key == KEY_KP_0:
		if ActorHoverInfo.GloballyVisible:
			MessageLog.PrintMessage("UI hidden")
			ActorHoverInfo.GloballyVisible = false
			ActorOverheadStats.GloballyVisible = false
			skillBar.visible = false
			initiativeBar.visible = false
		else:
			MessageLog.PrintMessage("UI shown")
			ActorHoverInfo.GloballyVisible = true
			ActorOverheadStats.GloballyVisible = true
			skillBar.visible = true
			initiativeBar.visible = true
	elif key == KEY_KP_1:
		ActorHoverInfo.GloballyVisible = !ActorHoverInfo.GloballyVisible
		MessageLog.PrintMessage("Hover info %s"%_getStatusWord(ActorHoverInfo.GloballyVisible))
	elif key == KEY_KP_2:
		ActorOverheadStats.GloballyVisible = !ActorOverheadStats.GloballyVisible
		MessageLog.PrintMessage("Overhead stats %s"%_getStatusWord(ActorOverheadStats.GloballyVisible))
	elif key == KEY_KP_3:
		skillBar.visible = !skillBar.visible
		MessageLog.PrintMessage("Skill bar %s"%_getStatusWord(skillBar.visible))
	elif key == KEY_KP_4:
		initiativeBar.visible = !initiativeBar.visible
		MessageLog.PrintMessage("Initiative bar %s"%_getStatusWord(initiativeBar.visible))

func _getStatusWord(status: bool):
	return "shown" if status else "hidden"
