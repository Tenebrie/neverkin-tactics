extends VisualizationLayer

var _currentField: PhysicsField
var _rayOrigin: Vector3
var _rayTarget: Vector3

func getMapActivationMessage() -> String:
	return "VisualizationLayer: PhysicsField raycast"

func updateRender():
	if not visible:
		return

	super.updateRender()

	_currentField = PhysicsField.new()
	_currentField.obstacles = PropWall.collectPhysicsFieldObstacles()

func _process(_delta: float) -> void:
	if not _currentField or not visible or not TurnManager.Instance.CurrentActor:
		return
	queue_redraw()

	var actor = TurnManager.Instance.CurrentActor
	var query = PhysicsFieldRaycastQuery.new()
	var target = ActorUtils.getMouseWorldPlanePosition(get_viewport())
	query.origin = actor.global_position
	query.target = target
	query.collision_mask = CollisionLayer.FULL_COVER | CollisionLayer.HIGH_COVER | CollisionLayer.LOW_COVER
	query.width = 0.25

	_rayOrigin = actor.global_position
	_rayTarget = target

	var result = _currentField.raycast_query(query)

	if result.has_hits:
		_rayTarget = result.get_hit_position(0)

func _draw():
	var camera = get_viewport().get_camera_3d()
	if not _currentField:
		return
	for obstacle in _currentField.obstacles:
		var r = obstacle.aabb
		var corners3D = [
			Vector3(r.position.x, 0, r.position.y),
			Vector3(r.end.x, 0, r.position.y),
			Vector3(r.end.x, 0, r.end.y),
			Vector3(r.position.x, 0, r.end.y),
		]
		var pts = PackedVector2Array()
		for c in corners3D:
			pts.push_back(camera.unproject_position(c))
		pts.push_back(pts[0])
		draw_polyline(pts, Color.RED, 2.0)

	if _rayOrigin and _rayTarget:
		draw_line(camera.unproject_position(_rayOrigin), camera.unproject_position(_rayTarget), Color.AQUAMARINE, worldLengthToPixels(camera, 0.25), true)

func worldLengthToPixels(camera: Camera3D, meters: float) -> float:
	var right = camera.global_transform.basis.x.normalized()
	var a = camera.unproject_position(Vector3.ZERO)
	var b = camera.unproject_position(Vector3.ZERO + right * meters)
	return a.distance_to(b)
