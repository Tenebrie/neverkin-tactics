extends Node
class_name NavmeshManager

const CIRCLE_SEGMENTS = 16

signal BakeCompleted
signal batchFinished

static var Instance: NavmeshManager:
	get:
		return NavmeshManagerInstance

var isBaking = false
var hasPendingRequest = false
var pendingActor: Actor = null
var pendingExceptions: Array[Actor] = []
var activeBakeCount = 0

func _enter_tree():
	TurnManager.Instance.CurrentActorChanged.connect(func(actor: Actor):
		rebakeNavmesh(actor, [])
	)
	Actor.SignalBus.ActorDestroyed.connect(func(actor: Actor):
		rebakeNavmesh(TurnManager.Instance.activeActor, [actor])
	)
	TurnManager.Instance.FactionTurnStarted.connect(func():
		if is_instance_valid(TurnManager.Instance.activeActor):
			rebakeNavmesh(TurnManager.Instance.activeActor, [])
	)

func WaitUntilReady():
	while isBaking or hasPendingRequest:
		await BakeCompleted

func rebakeNavmeshForCurrentActor():
	return await rebakeNavmesh(TurnManager.Instance.activeActor)

func rebakeNavmesh(actor: Actor, exceptions: Array[Actor] = []):
	if actor == null:
		return
	pendingActor = actor
	pendingExceptions = exceptions.duplicate()
	hasPendingRequest = true
	if not isBaking:
		drainQueue()
	return await WaitUntilReady()

func drainQueue():
	isBaking = true
	while hasPendingRequest:
		hasPendingRequest = false
		if is_instance_valid(pendingActor):
			var touchedMaps = await bakeOnce(pendingActor, pendingExceptions)
			await waitForMapSync(touchedMaps)
	isBaking = false
	BakeCompleted.emit()

func bakeOnce(actor: Actor, exceptions: Array[Actor]) -> Array[RID]:
	var bakeStartUsec := Time.get_ticks_usec()
	#print("[navbake] dispatch for %s" % [actor.name])
	var allExceptions: Array[Actor] = exceptions.duplicate()
	allExceptions.push_back(actor)
	var characters = get_tree().current_scene.find_children("*", "Actor", true, false)
	var regions = get_tree().current_scene.find_children("*", "NavigationRegion3D", true, false)
	var touchedMaps: Array[RID] = []
	var seenMeshes = {}
	activeBakeCount = 0
	for region: NavigationRegion3D in regions:
		var navMesh = region.navigation_mesh
		if navMesh == null:
			continue
		if seenMeshes.has(navMesh):
			continue
		seenMeshes[navMesh] = region.name
		if NavigationServer3D.is_baking_navigation_mesh(navMesh):
			continue
		navMesh.agent_radius = actor.physicalSize
		navMesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
		var source = NavigationMeshSourceGeometryData3D.new()
		NavigationServer3D.parse_source_geometry_data(navMesh, source, region)
		for c: Actor in characters:
			if c.isDead or allExceptions.has(c):
				continue
			var col: CollisionShape3D = c.get_node_or_null("CollisionShape3D")
			if col and col.shape:
				addObstruction(source, c, col, actor.physicalSize)
		touchedMaps.push_back(region.get_navigation_map())
		activeBakeCount += 1
		NavigationServer3D.bake_from_source_geometry_data_async(navMesh, source, onRegionBakeFinished)
	if activeBakeCount > 0:
		await batchFinished
	var elapsedMs := (Time.get_ticks_usec() - bakeStartUsec) / 1000.0
	if is_instance_valid(actor):
		print("[navbake] finished for %s in %.3f ms (%d region(s))" % [actor.name, elapsedMs, touchedMaps.size()])
	return touchedMaps

func GetRegion(rid: RID) -> NavigationRegion3D:
	var regions = GetAllRegions()
	var index = regions.find_custom(func(region):
		return region.get_rid() == rid
	)
	if index == -1:
		return null
	return regions[index]

func GetAllRegions() -> Array[NavigationRegion3D]:
	var result: Array[NavigationRegion3D] = []
	result.assign(get_tree().current_scene.find_children("*", "NavigationRegion3D", true, false))
	return result

func onRegionBakeFinished():
	activeBakeCount -= 1
	if activeBakeCount == 0:
		batchFinished.emit()

func waitForMapSync(maps: Array[RID]):
	var pending = {}
	for m in maps:
		pending[m] = true
	while not pending.is_empty():
		var synced: RID = await NavigationServer3D.map_changed
		pending.erase(synced)

func addObstruction(source: NavigationMeshSourceGeometryData3D, other: Actor, col: CollisionShape3D, agentRadius: float):
	var shape = col.shape
	var transform = col.global_transform
	var origin = transform.origin
	var colScale = transform.basis.get_scale()
	var horizontalScale = maxf(absf(colScale.x), absf(colScale.z))

	if shape is BoxShape3D:
		var heightA = shape.size.y * absf(colScale.y)
		var half = shape.size * 0.5 + Vector3(
			agentRadius / maxf(absf(colScale.x), 0.001),
			0,
			agentRadius / maxf(absf(colScale.z), 0.001)
		)
		var basis = transform.basis
		var verticesA = PackedVector3Array()
		for corner in [
			Vector3(-half.x, 0, -half.z),
			Vector3(half.x, 0, -half.z),
			Vector3(half.x, 0, half.z),
			Vector3(-half.x, 0, half.z),
		]:
			var rotated = basis * corner
			verticesA.push_back(Vector3(origin.x + rotated.x, 0, origin.z + rotated.z))
		source.add_projected_obstruction(verticesA, origin.y - heightA * 0.5, heightA, true)
		return

	var shapeRadius = 0.0
	var height = 0.0
	if shape is CapsuleShape3D:
		shapeRadius = shape.radius
		height = shape.height
	elif shape is CylinderShape3D:
		shapeRadius = shape.radius
		height = shape.height
	elif shape is SphereShape3D:
		shapeRadius = shape.radius
		height = shape.radius * 2.0
	else:
		push_warning("[navbake] Unsupported collision shape type: %s" % shape.get_class())
		return

	var footprint = maxf(shapeRadius * horizontalScale, other.physicalSize)
	height = height * absf(colScale.y)

	var carveRadius = footprint + agentRadius
	var vertices = PackedVector3Array()
	for i in CIRCLE_SEGMENTS:
		var angle = TAU * i / CIRCLE_SEGMENTS
		vertices.push_back(Vector3(
			origin.x + cos(angle) * carveRadius,
			0,
			origin.z + sin(angle) * carveRadius
		))
	source.add_projected_obstruction(vertices, origin.y - height * 0.5, height, true)
