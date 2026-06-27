extends Node
class_name TurnManager

static var Instance: TurnManager:
	get:
		return TurnManagerInstance

var CurrentActor: Actor = null
var PlayerControlledActors: Array[Actor] = []

signal KnownActorsChanged
signal CurrentActorChanged

func _ready():
	await get_tree().process_frame
	for actor in Actor.Repository.AllActors:
		if actor.HasComponent(PlayerController):
			PlayerControlledActors.push_back(actor)

	if PlayerControlledActors.size() == 0:
		return

	CurrentActor = PlayerControlledActors[0]
	NavmeshManager.Instance.RebakeNavmeshForActor(CurrentActor)
	KnownActorsChanged.emit()
	CurrentActorChanged.emit()

func EndTurn() -> void:
	for actor in PlayerControlledActors:
		if actor.actions.IsPerformingAnyAction():
			MessageLog.PrintMessage("Wait for animation pls")
			return

	for actor in PlayerControlledActors:
		actor.actions.EndTurn()
	MessageLog.PrintMessage("Next turn!")

func SelectCharacterByHotkey(index: int) -> void:
	if CurrentActor != null and CurrentActor.actions.IsPerformingAnyAction():
		return

	var selectedActor = PlayerControlledActors[index]
	if selectedActor == null:
		return

	CurrentActor = selectedActor
	NavmeshManager.Instance.RebakeNavmeshForActor(CurrentActor)
	CurrentActorChanged.emit()

func _unhandled_input(event: InputEvent) -> void:
	if event is not InputEventKey or not event.is_pressed():
		return

	if event.keycode == Key.KEY_ENTER:
		EndTurn()
