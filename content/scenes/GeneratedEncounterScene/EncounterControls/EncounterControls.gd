extends Control
class_name EncounterControls

signal generateNewEncounterRequested

@onready var toggleVisibilityButton: Button = %ToggleVisibilityButton
@onready var controlsContainer: PanelContainer = %ControlsContainer
@onready var snapshotCountLabel: Label = %SnapshotCountLabel
@onready var kinFactionControls: EncounterControlsFaction = %EncounterControlsFaction_Kin
@onready var wolfpackFactionControls: EncounterControlsFaction = %EncounterControlsFaction_Wolfpack

const DEFAULT_ARENA_SIZE = Vector2i(16, 10)

var arenaSize = DEFAULT_ARENA_SIZE

class FactionToSpawn:
	var faction: Actor.Faction
	var actors: Array[PackedScene]

func getFactionsToSpawn() -> Array[FactionToSpawn]:
	return [kinFactionControls.collect(), wolfpackFactionControls.collect()]

func _ready() -> void:
	EncounterControlsPrefs.Load(self)
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
	if kinFactionControls.getRows().is_empty():
		MessageLog.PrintMessage("You need at least one playable character")
		return

	EncounterControlsPrefs.Save(self)
	generateNewEncounterRequested.emit()

func _onResetEncounterButtonPressed() -> void:
	EncounterControlsPrefs.Reset()
	arenaSize = DEFAULT_ARENA_SIZE
	%SizeInputX.value = arenaSize.x
	%SizeInputY.value = arenaSize.y
	kinFactionControls.reset()
	wolfpackFactionControls.reset()

func _onSizeInputXChanged(value: float) -> void:
	arenaSize.x = roundi(value)

func _onSizeInputYChanged(value: float) -> void:
	arenaSize.y = roundi(value)
