extends Control

signal snapshotCreated
signal encounterRestarted

@onready var toggleVisibilityButton: Button = %ToggleVisibilityButton
@onready var controlsContainer: PanelContainer = %ControlsContainer

func _onToggleVisibilityButtonPressed() -> void:
	controlsContainer.visible = toggleVisibilityButton.button_pressed

func _onCreateSnapshotButtonPressed() -> void:
	snapshotCreated.emit()

func _onRestartEncounterButtonPressed() -> void:
	encounterRestarted.emit()
