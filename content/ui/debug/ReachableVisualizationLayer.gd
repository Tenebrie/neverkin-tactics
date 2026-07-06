extends VisualizationLayer

var lastSeenActor: Actor

func updateRender():
	if not visible:
		return

	if not TurnManager.Instance.ActorTakingTurn:
		return

	var actor = TurnManager.Instance.ActorTakingTurn
	if not actor or not actor.navigator or lastSeenActor == actor:
		return

	super.updateRender()
	lastSeenActor = actor

	var coverMap = BehaviourUtils.CreateActorCoverMap(actor)
	var points = coverMap.Points.filter(func(point): return ActorUtils.IsPointReachable(actor, point, 1))

	for point in points:
		setPointValue(coverMap.Read(point), point)
