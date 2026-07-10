extends Node
class_name TurnManager

static var Instance: TurnManager:
	get:
		return TurnManagerInstance

var activePlayerActor: Actor = null
var activeWorldActor: Actor = null
var activeActor: Actor:
	get:
		if activeFaction == Actor.PlayerFaction:
			return activePlayerActor
		return activeWorldActor
var playerControlledActors: Array[Actor] = []

signal KnownActorsChanged
signal CurrentActorChanged(actor: Actor, previous: Actor)
signal CurrentPlayerActorChanged(actor: Actor, previous: Actor)
signal BeforeFactionTurnEnded(faction: Actor.Faction)
signal FactionTurnStarted(faction: Actor.Faction)
signal FactionTurnEnded(faction: Actor.Faction)
signal TurnChanged

var activeFaction: Actor.Faction = Actor.PlayerFaction

func _ready():
	await get_tree().process_frame
	loadPlayerControlledActors()
	await get_tree().process_frame
	startTurnForCurrentFaction()

func setPlayerFaction(faction: Actor.Faction):
	var factionHasActors = false
	for actor in Actor.Repository.All.List:
		if actor.faction == faction and actor.Behaviour:
			factionHasActors = true
			break
	if not factionHasActors:
		MessageLog.PrintMessage("Unable to switch to faction %s as it has no controllable actors"%Actor.Faction.keys()[faction + 1])
		return
	Actor.PlayerFaction = faction
	loadPlayerControlledActors()
	advanceTurn()

func loadPlayerControlledActors():
	playerControlledActors = []
	for actor in Actor.Repository.All.List:
		if actor.faction == Actor.PlayerFaction:
			playerControlledActors.push_back(actor)
	playerControlledActors.sort_custom(func(a, b):
		return a.initiative > b.initiative
	)

	if playerControlledActors.size() > 0:
		activePlayerActor = playerControlledActors[0]

	KnownActorsChanged.emit()
	CurrentActorChanged.emit(activeActor, null)
	CurrentPlayerActorChanged.emit(activePlayerActor, null)

func endPlayerTurn() -> void:
	if activeFaction != Actor.PlayerFaction:
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
	await SignalUtils.emitAsync([BeforeFactionTurnEnded, FactionTurnEnded], activeFaction)
	activeFaction = (activeFaction + 1) as Actor.Faction
	if activeFaction >= Actor.Faction.size() - 1:
		activeFaction = Actor.PlayerFaction
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
	#FactionTurnStarted.emit(activeFaction)
	await SignalUtils.emitAsync([FactionTurnStarted], activeFaction)
	if activeFaction == Actor.PlayerFaction:
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
