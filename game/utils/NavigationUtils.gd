class_name NavigationUtils

static func getPath(mapRid: RID, origin: Vector3, point: Vector3, navigationLayers = 1) -> PackedVector3Array:
	var snappedOrigin = NavigationServer3D.map_get_closest_point(mapRid, origin)
	var target = NavigationServer3D.map_get_closest_point(mapRid, point)
	return NavigationServer3D.map_get_path(mapRid, snappedOrigin, target, true, navigationLayers)

static func isPointReachable(mapRid: RID, origin: Vector3, point: Vector3, maxDistance: float, navigationLayers = 1) -> bool:
	var snappedOrigin = NavigationServer3D.map_get_closest_point(mapRid, origin)
	var target = NavigationServer3D.map_get_closest_point(mapRid, point)
	var path = NavigationServer3D.map_get_path(mapRid, snappedOrigin, target, true, navigationLayers)
	if path.is_empty() or path[-1].distance_squared_to(target) > 0.01:
		return false
	return getPathLength(path) <= maxDistance

static func getPathLength(points: PackedVector3Array) -> float:
	var result = 0.0

	for i in range(1, points.size()):
		var seg = points[i] - points[i - 1]
		var seg_len = seg.length()
		result += seg_len

	return result
