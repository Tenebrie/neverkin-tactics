extends Node
class_name TurnManager

static var Instance: TurnManager:
	get:
		return TurnManagerInstance

var activePlayerActor: Actor = null
var activeWorldActor: Actor = null
var activeActor: Actor:
	get:
		if activeFaction == Actor.Faction.Player:
			return activePlayerActor
		return activeWorldActor
var playerControlledActors: Array[Actor] = []

signal KnownActorsChanged
signal CurrentActorChanged(actor: Actor, previous: Actor)
signal CurrentPlayerActorChanged(actor: Actor, previous: Actor)
signal FactionTurnStarted(faction: Actor.Faction)
signal FactionTurnEnded(faction: Actor.Faction)
signal TurnChanged

var activeFaction: Actor.Faction = Actor.Faction.Player

func _ready():
	await get_tree().process_frame
	for actor in Actor.Repository.All.List:
		if actor.HasComponent(ActorBehaviourPlayerControlled):
			playerControlledActors.push_back(actor)

	if playerControlledActors.size() == 0:
		return

	activePlayerActor = playerControlledActors[0]
	KnownActorsChanged.emit()
	CurrentActorChanged.emit(activeActor, null)
	CurrentPlayerActorChanged.emit(activePlayerActor, null)
	await get_tree().process_frame
	startTurnForCurrentFaction()

func endPlayerTurn() -> void:
	if activeFaction != Actor.Faction.Player:
		MessageLog.PrintMessage("Uncool, let them play")
		return
	for actor in playerControlledActors:
		if is_instance_valid(actor) and actor.actions.IsPerformingAnyAction():
			MessageLog.PrintMessage("Wait for animation pls")
			return

	advanceTurn()

func endWorldTurn() -> void:
	activateWorldActor(null)
	advanceTurn()

func advanceTurn():
	var previousActor = activeActor
	activateWorldActor(null)
	FactionTurnEnded.emit(activeFaction)
	activeFaction = (activeFaction + 1) as Actor.Faction
	if activeFaction >= Actor.Faction.size() - 1:
		activeFaction = Actor.Faction.Player
	var factionHasActors = Actor.Repository.Alive.List.any(func(a):
		return a.Stats.Faction == activeFaction and a.HasComponent(ActorBehaviour)
	)
	if not factionHasActors:
		advanceTurn()
		return
	startTurnForCurrentFaction()
	if activeActor != previousActor:
		CurrentActorChanged.emit(activeActor, previousActor)

func startTurnForCurrentFaction():
	MessageLog.PrintChatMessage("Turn Start: %s"%Actor.Faction.keys()[activeFaction + 1])
	TurnChanged.emit()
	FactionTurnStarted.emit(activeFaction)
	if activeFaction == Actor.Faction.Player:
		startPlayerTurn()

func startPlayerTurn():
	if activePlayerActor and not activePlayerActor.isDead:
		return

	for i in playerControlledActors.size():
		var actor = playerControlledActors[i]
		if actor.isAlive:
			activatePlayerActorByHotkey(i)
			return

func activatePlayerActorByHotkey(index: int) -> void:
	if activePlayerActor != null and activePlayerActor.actions.IsPerformingAnyAction():
		return

	var selectedActor = playerControlledActors[index]
	if selectedActor == null or activePlayerActor == selectedActor:
		return

	if selectedActor.isDead:
		MessageLog.PrintMessage("%s is incapacitated!"%selectedActor.Definition.Name)
		return

	var previousActor = activePlayerActor
	activePlayerActor = selectedActor
	if not is_instance_valid(previousActor):
		previousActor = null
	CurrentActorChanged.emit(activePlayerActor, previousActor)
	CurrentPlayerActorChanged.emit(activePlayerActor, previousActor)

func activateWorldActor(actor: Actor) -> void:
	var previousActor = activeWorldActor
	activeWorldActor = actor
	CurrentActorChanged.emit(activeWorldActor, previousActor)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("endTurn"):
		endPlayerTurn()

	if event.is_action_pressed("fastForwardAnimations"):
		Engine.time_scale = 4.0
	elif event.is_action_released("fastForwardAnimations"):
		Engine.time_scale = 1.0
