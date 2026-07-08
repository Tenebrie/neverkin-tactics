extends Node
class_name TurnManager

static var Instance: TurnManager:
	get:
		return TurnManagerInstance

var CurrentActor: Actor = null
var CurrentNPC: Actor = null
var ActorTakingTurn: Actor:
	get:
		if CurrentFaction == Actor.Faction.Player:
			return CurrentActor
		return CurrentNPC
var PlayerControlledActors: Array[Actor] = []

signal KnownActorsChanged
signal CurrentActorChanged(actor: Actor, previous: Actor)
signal CurrentPlayerActorChanged(actor: Actor, previous: Actor)
signal FactionTurnStarted(faction: Actor.Faction)
signal FactionTurnEnded(faction: Actor.Faction)
signal TurnChanged

var CurrentFaction: Actor.Faction = Actor.Faction.Player

func _ready():
	await get_tree().process_frame
	for actor in Actor.Repository.All.List:
		if actor.HasComponent(ActorBehaviourPlayerControlled):
			PlayerControlledActors.push_back(actor)

	if PlayerControlledActors.size() == 0:
		return

	CurrentActor = PlayerControlledActors[0]
	KnownActorsChanged.emit()
	CurrentActorChanged.emit(ActorTakingTurn, null)
	CurrentPlayerActorChanged.emit(CurrentActor, null)
	await get_tree().process_frame
	startTurnForCurrentFaction()

func EndPlayerTurn() -> void:
	if CurrentFaction != Actor.Faction.Player:
		MessageLog.PrintMessage("Uncool, let them play")
		return
	for actor in PlayerControlledActors:
		if is_instance_valid(actor) and actor.actions.IsPerformingAnyAction():
			MessageLog.PrintMessage("Wait for animation pls")
			return

	advanceTurn()

func EndWorldTurn() -> void:
	SelectNonPlayableActor(null)
	advanceTurn()

func advanceTurn():
	var previousActor = ActorTakingTurn
	SelectNonPlayableActor(null)
	FactionTurnEnded.emit(CurrentFaction)
	CurrentFaction = (CurrentFaction + 1) as Actor.Faction
	if CurrentFaction >= Actor.Faction.size() - 1:
		CurrentFaction = Actor.Faction.Player
	var factionHasActors = Actor.Repository.Alive.List.any(func(a):
		return a.Stats.Faction == CurrentFaction and a.HasComponent(ActorBehaviour)
	)
	if not factionHasActors:
		advanceTurn()
		return
	startTurnForCurrentFaction()
	if ActorTakingTurn != previousActor:
		CurrentActorChanged.emit(ActorTakingTurn, previousActor)

func startTurnForCurrentFaction():
	MessageLog.PrintChatMessage("Turn Start: %s"%Actor.Faction.keys()[CurrentFaction + 1])
	TurnChanged.emit()
	FactionTurnStarted.emit(CurrentFaction)

func SelectCharacterByHotkey(index: int) -> void:
	if CurrentActor != null and CurrentActor.actions.IsPerformingAnyAction():
		return

	var selectedActor = PlayerControlledActors[index]
	if selectedActor == null or CurrentActor == selectedActor:
		return

	var previousActor = CurrentActor
	CurrentActor = selectedActor
	if not is_instance_valid(previousActor):
		previousActor = null
	CurrentActorChanged.emit(CurrentActor, previousActor)
	CurrentPlayerActorChanged.emit(CurrentActor, previousActor)

func SelectNonPlayableActor(actor: Actor) -> void:
	var previousActor = CurrentNPC
	CurrentNPC = actor
	CurrentActorChanged.emit(CurrentNPC, previousActor)

func _unhandled_input(event: InputEvent) -> void:
	if event is not InputEventKey or not event.is_pressed():
		return

	if event.keycode == Key.KEY_ENTER:
		EndPlayerTurn()
