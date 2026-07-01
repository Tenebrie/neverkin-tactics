extends Node
class_name NavmeshManager

const CIRCLE_SEGMENTS = 12

static var Instance: NavmeshManager:
	get:
		return NavmeshManagerInstance

@onready var TrackedActorSignal = SignalTracker.new(
	func(actor: Actor): return actor.DefinitionChanged,
	RebakeNavmeshForCurrentActor
)

func _enter_tree() -> void:
	TurnManager.Instance.CurrentActorChanged.connect(onCurrentActorChanged)
	Actor.SignalBus.ActorDestroyed.connect(func(actor):
		rebakeNavmesh(TurnManager.Instance.CurrentActor, [actor])
	)

func RebakeNavmeshForCurrentActor():
	rebakeNavmesh(TurnManager.Instance.CurrentActor, [])

func onCurrentActorChanged(actor: Actor) -> void:
	await get_tree().process_frame
	TrackedActorSignal.Track(actor)
	rebakeNavmesh(actor, [])

func rebakeNavmesh(actor: Actor, exceptions: Array[Actor]) -> void:
	var total_start := Time.get_ticks_usec()
	exceptions.push_back(actor)
	var characters := get_tree().current_scene.find_children("*", "Actor", true, false)
	var regions := get_tree().current_scene.find_children("*", "NavigationRegion3D", true, false)

	for region: NavigationRegion3D in regions:
		region.navigation_mesh.agent_radius = actor.PhysicalSize
		var nav_mesh := region.navigation_mesh
		region.navigation_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
		if nav_mesh == null:
			continue

		var source := NavigationMeshSourceGeometryData3D.new()
		NavigationServer3D.parse_source_geometry_data(nav_mesh, source, region)

		for c: Actor in characters:
			if exceptions.has(c):
				continue
			var col: CollisionShape3D = c.get_node_or_null("CollisionShape3D")
			if col and col.shape:
				addObstruction(source, col, actor.PhysicalSize)

		NavigationServer3D.bake_from_source_geometry_data_async(nav_mesh, source)

	var total_ms := (Time.get_ticks_usec() - total_start) / 1000.0
	print("[navbake] all regions done in %.2f ms" % total_ms)

func addObstruction(source: NavigationMeshSourceGeometryData3D, col: CollisionShape3D, agentRadius: float):
	var shape := col.shape
	var origin := col.global_position
	var radius := 0.0
	var height := 0.0

	if shape is CapsuleShape3D:
		radius = shape.radius
		height = shape.height
	elif shape is CylinderShape3D:
		radius = shape.radius
		height = shape.height
	elif shape is SphereShape3D:
		radius = shape.radius
		height = radius * 2.0
	elif shape is BoxShape3D:
		height = shape.size.y
		var half := shape.size * 0.5 + Vector3(agentRadius, 0, agentRadius)
		var basis := col.global_transform.basis
		var vertices := PackedVector3Array()
		for corner in [
			Vector3(-half.x, 0, -half.z),
			Vector3(half.x, 0, -half.z),
			Vector3(half.x, 0, half.z),
			Vector3(-half.x, 0, half.z),
		]:
			var rotated := basis * corner
			vertices.push_back(Vector3(origin.x + rotated.x, 0, origin.z + rotated.z))
		source.add_projected_obstruction(vertices, origin.y - height * 0.5, height, true)
		return
	else:
		push_warning("[navbake] Unsupported collision shape type: %s" % shape.get_class())
		return

	# Circular footprint for capsule/cylinder/sphere, inflated by agent radius
	radius += agentRadius
	var otherVertices := PackedVector3Array()
	for i in CIRCLE_SEGMENTS:
		var angle := TAU * i / CIRCLE_SEGMENTS
		otherVertices.push_back(Vector3(
			origin.x + cos(angle) * radius,
			0,
			origin.z + sin(angle) * radius
		))
	source.add_projected_obstruction(otherVertices, origin.y - height * 0.5, height, true)
