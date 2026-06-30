extends Node
class_name NavmeshManager

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
		if nav_mesh == null:
			continue

		var source := NavigationMeshSourceGeometryData3D.new()

		NavigationServer3D.parse_source_geometry_data(nav_mesh, source, region)

		for c: Actor in characters:
			if exceptions.has(c):
				continue
			var col: CollisionShape3D = c.get_node_or_null("CollisionShape3D")
			if col and col.shape:
				var faces := col.shape.get_debug_mesh().get_faces()
				source.add_faces(faces, col.global_transform)

		NavigationServer3D.bake_from_source_geometry_data_async(nav_mesh, source)


	var total_ms := (Time.get_ticks_usec() - total_start) / 1000.0
	print("[navbake] all regions done in %.2f ms" % total_ms)
