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

static var _classAncestorDict: Dictionary[GDScript, Dictionary] = {}

static func GetClassAncestors(script: GDScript) -> Dictionary:
	if _classAncestorDict.has(script):
		return _classAncestorDict[script]
	var elementSet: Dictionary[GDScript, bool] = {}
	var cur = script
	while cur != null:
		elementSet[cur] = true
		cur = cur.get_base_script()
	_classAncestorDict[script] = elementSet
	return elementSet

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

static func GetMouseWorldPlanePosition(viewport: Viewport) -> Vector3:
	var camera := viewport.get_camera_3d()
	var mouse_pos := viewport.get_mouse_position()
	var origin := camera.project_ray_origin(mouse_pos)
	var direction := camera.project_ray_normal(mouse_pos)

	# Intersect with Y=0 plane
	var plane := Plane(Vector3.UP, 0.0)
	var intersection: Vector3 = plane.intersects_ray(origin, direction)

	if intersection:
		return intersection
	return Vector3.ZERO

static func GetAllianceColor(alliance: Actor.Alliance) -> Color:
	if alliance == Actor.Alliance.Player:
		return Color.DARK_GREEN
	elif alliance == Actor.Alliance.Hostile:
		return Color.DARK_RED
	return Color.GRAY
