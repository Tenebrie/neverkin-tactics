extends VisualizationLayer

var _currentField: PhysicsFieldState
var _rayOrigin: Vector3
var _rayTarget: Vector3

func updateRender():
	if not visible:
		return

	super.updateRender()

	_currentField = PhysicsField.build_state(PropWall.collectPhysicsFieldObstacles())

func _process(delta: float) -> void:
	if not _currentField or not visible or not TurnManager.Instance.CurrentActor:
		return
	queue_redraw()

	var actor = TurnManager.Instance.CurrentActor
	var query = PhysicsFieldRaycastQuery.new()
	var target = ActorUtils.GetMouseWorldPlanePosition(get_viewport())
	query.origin = actor.global_position
	query.target = target

	_rayOrigin = actor.global_position
	_rayTarget = target

	var result = PhysicsField.raycast_query(_currentField, query)
	if result.has_hits:
		_rayTarget = result.hits[0].position

	var raysToTest = 3000

	var timer = PerformanceUtils.startMeasure("Running %d rays"%raysToTest)
	for i in raysToTest:
		PhysicsField.raycast_query(_currentField, query)
	timer.endMeasure()

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
		draw_line(camera.unproject_position(_rayOrigin), camera.unproject_position(_rayTarget), Color.AQUAMARINE, 4)
