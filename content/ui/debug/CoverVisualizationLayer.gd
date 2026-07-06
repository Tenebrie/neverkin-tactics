extends VisualizationLayer

var lastSeenActor: Actor

func updateRender():
	if not visible:
		return

	if not TurnManager.Instance.ActorTakingTurn:
		return

	var currentActor: Actor
	if not Actor.Repository.Hovered.List.is_empty():
		currentActor = Actor.Repository.Hovered.List[0]
	else:
		currentActor = TurnManager.Instance.ActorTakingTurn
	if not currentActor or not currentActor.navigator:
		return

	if lastSeenActor == currentActor:
		return

	super.updateRender()
	lastSeenActor = currentActor

	var coverMap = BehaviourUtils.CreateActorCoverMap(currentActor)

	for point in coverMap.Points:
		setPointValue(coverMap.Read(point), point)
