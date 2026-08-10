extends Control
class_name EncounterControls

signal generateNewEncounterRequested

@onready var toggleVisibilityButton: Button = %ToggleVisibilityButton
@onready var controlsContainer: PanelContainer = %ControlsContainer
@onready var snapshotCountLabel: Label = %SnapshotCountLabel
@onready var kinFactionControls: EncounterControlsFaction = %EncounterControlsFaction_Kin
@onready var wolfpackFactionControls: EncounterControlsFaction = %EncounterControlsFaction_Wolfpack

var arenaSize = Vector2i(16, 10)

class FactionToSpawn:
	var faction: Actor.Faction
	var actors: Array[PackedScene]

func getFactionsToSpawn() -> Array[FactionToSpawn]:
	return [kinFactionControls.collect(), wolfpackFactionControls.collect()]

func _ready() -> void:
	_updateSnapshotCount()
	SnapshotManager.snapshotsChanged.connect(_updateSnapshotCount)
	SnapshotManager.snapshotRestored.connect(_updateSnapshotCount)
	%SizeInputX.value = arenaSize.x
	%SizeInputY.value = arenaSize.y

func _updateSnapshotCount():
	var dirtyFlag = "*" if SnapshotManager.snapshotDirty else " "
	snapshotCountLabel.text = "%d%s/ %d"%[SnapshotManager.snapshotHead + 1, dirtyFlag, SnapshotManager.snapshots.size()]

func _onToggleVisibilityButtonPressed() -> void:
	controlsContainer.visible = toggleVisibilityButton.button_pressed

func _onUndoSnapshotPressed() -> void:
	SnapshotManager.RestorePreviousSnapshot()

func _onRedoSnapshotPressed() -> void:
	SnapshotManager.RestoreNextSnapshot()

func _onRestartEncounterButtonPressed() -> void:
	SnapshotManager.RestoreEarliestSnapshot()

func _onGenerateNewEncounterButtonPressed() -> void:
	generateNewEncounterRequested.emit()

func _onSizeInputXChanged(value: float) -> void:
	arenaSize.x = roundi(value)

func _onSizeInputYChanged(value: float) -> void:
	arenaSize.y = roundi(value)
