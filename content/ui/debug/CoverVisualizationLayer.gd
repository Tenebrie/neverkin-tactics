extends VisualizationLayer

var lastSeenActor: Actor
var isRendering = false

func updateRender():
	if isRendering or not visible:
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

	isRendering = true
	var coverMap = await BehaviourUtils.CreateActorCoverMap(currentActor)

	for point in coverMap.Points:
		setPointValue(coverMap.Read(point), point)
	isRendering = false
