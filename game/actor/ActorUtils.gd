class_name ActorUtils

static func GetPathCompletedPercentage(path: PackedVector3Array, position: Vector3) -> float:
	if path.size() < 2:
		return 1.0
	var pos := Vector3(position.x, 0.0, position.z)
	var totalLength := 0.0
	for i in path.size() - 1:
		var a := Vector3(path[i].x, 0.0, path[i].z)
		var b := Vector3(path[i + 1].x, 0.0, path[i + 1].z)
		totalLength += (b - a).length()
	if totalLength <= 0.0:
		return 1.0
	var bestDist := INF
	var traversed := 0.0
	var lengthBeforeSegment := 0.0
	for i in path.size() - 1:
		var a := Vector3(path[i].x, 0.0, path[i].z)
		var b := Vector3(path[i + 1].x, 0.0, path[i + 1].z)
		var ab := b - a
		var lenSq := ab.length_squared()
		var t := 0.0
		if lenSq > 0.0000001:
			t = clampf((pos - a).dot(ab) / lenSq, 0.0, 1.0)
		var closest := a + ab * t
		var d := pos.distance_squared_to(closest)
		if d < bestDist:
			bestDist = d
			traversed = lengthBeforeSegment + sqrt(lenSq) * t
		lengthBeforeSegment += sqrt(lenSq)
	return clampf(traversed / totalLength, 0.0, 1.0)

static func LimitPathLength(points: PackedVector3Array, maxLength: float) -> PackedVector3Array:
	if points.size() < 2 or maxLength <= 0.0:
		return PackedVector3Array() if points.is_empty() else PackedVector3Array([points[0]])

	var result := PackedVector3Array([points[0]])
	var remaining := maxLength

	for i in range(1, points.size()):
		var seg := points[i] - points[i - 1]
		var seg_len := seg.length()

		if seg_len <= remaining:
			result.append(points[i])
			remaining -= seg_len
		else:
			result.append(points[i - 1] + seg * (remaining / seg_len))
			break

	return result

static func GetPathLength(points: PackedVector3Array) -> float:
	var result = 0.0

	for i in range(1, points.size()):
		var seg = points[i] - points[i - 1]
		var seg_len = seg.length()
		result += seg_len

	return result

static func GetPathTo(actor: Actor, point: Vector3) -> PackedVector3Array:
	var mapRid = actor.navigator.agent.get_navigation_map()
	var target = NavigationServer3D.map_get_closest_point(mapRid, point)

	return NavigationServer3D.map_get_path(
		mapRid,
		actor.global_position,
		target,
		true,
		actor.navigator.agent.navigation_layers
	)

static func IsPointReachable(actor: Actor, point: Vector3, actionLimit: int) -> bool:
	var length = GetPathLength(GetPathTo(actor, point))
	return length <= (actor.Definition.MovementSpeedPerActionPoint * actionLimit)

static func GetMouseWorldPlanePosition(viewport: Viewport) -> Vector3:
	var camera := viewport.get_camera_3d()
	var mouse_pos := viewport.get_mouse_position()
	var origin := camera.project_ray_origin(mouse_pos)
	var direction := camera.project_ray_normal(mouse_pos)
	if not origin or not direction:
		return Vector3.ZERO

	# Intersect with Y=0 plane
	var plane := Plane(Vector3.UP, 0.0)
	var intersection: Variant = plane.intersects_ray(origin, direction)

	if intersection:
		return intersection
	return Vector3.ZERO

static func GetAllianceColor(alliance: Actor.Alliance) -> Color:
	if alliance == Actor.Alliance.Player:
		return Color("4deb4b")
	elif alliance == Actor.Alliance.CityThugs:
		return Color("eb4d4b")
	elif alliance == Actor.Alliance.Algae:
		return Color("4b4deb")
	return Color.GRAY

static func GetFactionName(faction: Actor.Alliance) -> String:
	if faction == Actor.Alliance.Player:
		return "Player"
	elif faction == Actor.Alliance.CityThugs:
		return "Thugs"
	elif faction == Actor.Alliance.Algae:
		return "Bloom"
	return "Neutral"

static func GetThreatLevelColor(threatValue: float) -> Color:
	var threat = floori(threatValue)
	match threat:
		Actor.ThreatLevel.Harmless:
			return Color("a8a8a8")
		Actor.ThreatLevel.Concerning:
			return Color("f2d94e")
		Actor.ThreatLevel.Dangerous:
			return Color("f0932b")
		Actor.ThreatLevel.Deadly:
			return Color("eb4d4b")
		_:
			# Existential and beyond: shift toward a hot magenta/violet,
			# getting brighter the further past Existential we go
			var overcap = threat - Actor.ThreatLevel.Existential
			var base = Color("c0392b")
			var peak = Color("ff2fd0")
			return base.lerp(peak, clampf(overcap * 0.25 + 0.4, 0.0, 1.0))

static func GetThreatLevelName(threatValue: float) -> String:
	var threat = floori(threatValue)
	if threat <= Actor.ThreatLevel.Existential:
		return Actor.ThreatLevel.keys()[clampi(threat, 0, Actor.ThreatLevel.Existential)]
	var overcap = threat - Actor.ThreatLevel.Existential
	return Actor.ThreatLevel.keys()[Actor.ThreatLevel.Existential] + "+".repeat(overcap)

static func IsTargetableBy(a: Actor, b: Actor) -> bool:
	var aa: Actor.Alliance = a.Definition.Alliance
	var bb: Actor.Alliance = b.Definition.Alliance
	if aa == Actor.Alliance.Neutral or bb == Actor.Alliance.Neutral:
		return true
	return aa != bb

static func IsHostileTo(a: Actor, b: Actor) -> bool:
	var aa: Actor.Alliance = a.Definition.Alliance
	var bb: Actor.Alliance = b.Definition.Alliance
	if aa == Actor.Alliance.Neutral or bb == Actor.Alliance.Neutral:
		return false
	return aa != bb

static func FlatPositionOf(node: Node3D) -> Vector3:
	return Vector3(node.global_position.x, 0.0, node.global_position.z)

static func FlatDistanceBetween(a: Node3D, b: Node3D) -> float:
	return FlatPositionOf(a).distance_to(FlatPositionOf(b))

static func FlatDistanceTo(node: Node3D, point: Vector3) -> float:
	point.y = 0.0
	return FlatPositionOf(node).distance_to(point)

static func FlatDirectionTo(from: Actor, toPoint: Vector3) -> Vector3:
	var origin = from.global_position
	origin.y = 0.0
	toPoint.y = 0.0
	return origin.direction_to(toPoint)

static func HasLineOfSight(actor: Actor, target: Actor) -> bool:
	var physicsField = PhysicsField.new()
	physicsField.obstacles = PropWall.collectPhysicsFieldObstacles()
	var query = PhysicsFieldRaycastQuery.new()
	query.width = 0.1
	query.origin = actor.global_position
	query.target = target.global_position
	query.collision_mask = CollisionLayer.FULL_COVER | CollisionLayer.HIGH_COVER | CollisionLayer.LOW_COVER
	query.exclude = PropWall.GetIgnoredWallRidsAt(PropWall.collectBehaviourMapTaskData(), actor.global_position, actor.PhysicalSize)
	var result = physicsField.raycast_query(query)
	return not result.has_hits
