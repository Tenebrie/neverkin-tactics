extends VisualizationLayer

var lastSeenActor: Actor
var isRendering = false

func getMapActivationMessage() -> String:
	return "VisualizationLayer: Actor line-of-sight"

func updateRender():
	if isRendering or not visible:
		return

	if not TurnManager.Instance.activeActor:
		return

	var actor: Actor
	if not Actor.Repository.Hovered.List.is_empty():
		actor = Actor.Repository.Hovered.List[0]
	elif lastSeenActor and is_instance_valid(lastSeenActor):
		actor = lastSeenActor
	else:
		actor = TurnManager.Instance.activeActor

	if not actor or not actor.navigator or lastSeenActor == actor:
		return

	super.updateRender()
	lastSeenActor = actor

	isRendering = true
	await NavmeshManager.Instance.rebakeNavmesh(actor)
	var coverMap = await BehaviourUtils.createActorLineOfSightMap(actor)
	var reachablePoints = await ActorUtils.getReachablePointsAsync(actor, coverMap.points, 1)

	for point in reachablePoints:
		setPointValue(coverMap.read(point), point)
	isRendering = false
