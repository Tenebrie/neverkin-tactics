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
