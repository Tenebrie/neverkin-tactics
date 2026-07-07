extends VisualizationLayer

var lastSeenActor: Actor
var isRendering = false

func updateRender():
	if isRendering or not visible:
		return

	if not TurnManager.Instance.ActorTakingTurn:
		return

	var actor = TurnManager.Instance.ActorTakingTurn
	if not actor or not actor.navigator or lastSeenActor == actor:
		return

	super.updateRender()
	lastSeenActor = actor

	isRendering = true
	var coverMap = await BehaviourUtils.CreateActorCoverMap(actor)
	var points = coverMap.Points.filter(func(point): return ActorUtils.IsPointReachable(actor, point, 1))

	for point in points:
		setPointValue(coverMap.Read(point), point)
	isRendering = false
