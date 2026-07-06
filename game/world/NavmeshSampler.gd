class_name NavmeshSampler

class NavmeshSample:
	var points: Array[Vector3]

static func CollectNavmeshPoints(actor: Actor, outputDensity: float, oversample: float = 0.0) -> NavmeshSample:
	var currentMapRid = actor.navigator.agent.get_navigation_map()
	var currentRegionRid = NavigationServer3D.map_get_closest_point_owner(currentMapRid, actor.global_position)

	var navMesh = NavmeshManager.Instance.GetRegion(currentRegionRid)
	if not navMesh:
		MessageLog.PrintMessage("Unable to find navmesh to collect points")
		return null

	var gridState: Dictionary[Vector2i, Vector3]

	var movementSpeed = actor.Definition.MovementSpeedPerActionPoint + oversample
	var maxDistSquared = pow(movementSpeed + oversample, 2)
	var boxSize = Vector3(movementSpeed, 0, movementSpeed)
	var aabb = AABB(actor.global_position - boxSize, boxSize * 2)
	var rawSurfaces = sampleSurfacePoints(currentMapRid, aabb, clampf((movementSpeed - oversample) / 8.0, 0.5, 10.0))
	var rawEdges = sampleEdgePoints(navMesh, 0.5)

	var sample = NavmeshSample.new()

	if tryClaim(gridState, actor.global_position + Vector3(0, 0.01, 0), outputDensity):
		sample.points.push_back(actor.global_position + Vector3(0, 0.01, 0))

	for point in rawEdges:
		if point.distance_squared_to(actor.global_position) > maxDistSquared:
			continue
		if tryClaim(gridState, point, outputDensity):
			sample.points.push_back(point)
			#print(toCellCoordinates(point, outputDensity))

	for point in rawSurfaces:
		if point.distance_squared_to(actor.global_position) > maxDistSquared:
			continue
		if tryClaim(gridState, point, outputDensity):
			sample.points.push_back(point)


	return sample

static func sampleEdgePoints(nav_region: NavigationRegion3D, spacing: float) -> Array[Vector3]:
	var nav_mesh = nav_region.navigation_mesh
	var verts = nav_mesh.get_vertices()
	var xform = nav_region.global_transform

	# Count edge usage to find boundary edges
	var edge_count = {}
	for i in nav_mesh.get_polygon_count():
		var poly = nav_mesh.get_polygon(i)
		for j in poly.size():
			var a = poly[j]
			var b = poly[(j + 1) % poly.size()]
			var key = Vector2i(mini(a, b), maxi(a, b))
			edge_count[key] = edge_count.get(key, 0) + 1

	var boundary: Array[Vector2i] = []
	for key: Vector2i in edge_count:
		if edge_count[key] == 1:
			boundary.append(key)
	boundary.sort()  # canonical order → stable output

	var result: Array[Vector3] = []
	for e in boundary:
		var p0 = xform * verts[e.x]
		var p1 = xform * verts[e.y]
		var length = p0.distance_to(p1)
		var steps = maxi(1, int(length / spacing))
		# place points at even fractions; include start, exclude end to avoid
		# double-counting shared endpoints between consecutive edges
		for s in steps:
			result.append(p0.lerp(p1, float(s) / float(steps)))
	return result

static func sampleSurfacePoints(map_rid: RID, bounds: AABB, spacing: float) -> Array[Vector3]:
	var result: Array[Vector3] = []

	var start_ix = int(floor(bounds.position.x / spacing))
	var end_ix   = int(ceil((bounds.position.x + bounds.size.x) / spacing))
	var start_iz = int(floor(bounds.position.z / spacing))
	var end_iz   = int(ceil((bounds.position.z + bounds.size.z) / spacing))

	for ix in range(start_ix, end_ix + 1):
		for iz in range(start_iz, end_iz + 1):
			var query = Vector3(ix * spacing, bounds.position.y, iz * spacing)
			var on_mesh = NavigationServer3D.map_get_closest_point(map_rid, query)
			# keep only if the nearest navmesh point is close to the grid point
			if Vector2(query.x - on_mesh.x, query.z - on_mesh.z).length() < spacing * 0.5:
				result.append(on_mesh)

	return result

static func tryClaim(state: Dictionary[Vector2i, Vector3], point: Vector3, cellSize: float) -> bool:
	var cx := int(floor(point.x / cellSize))
	var cz := int(floor(point.z / cellSize))
	# check this cell + 8 neighbors, since a point near a cell edge can be
	# within cullRadius of a point in an adjacent cell
	for dx in [-1, 0, 1]:
		for dz in [-1, 0, 1]:
			var key := Vector2i(cx + dx, cz + dz)
			if state.has(key):
				var existing: Vector3 = state[key]
				if existing.distance_squared_to(point) < cellSize * cellSize:
					return false
	state[Vector2i(cx, cz)] = point
	return true

static func toCellCoordinates(point: Vector3, gridSize: float) -> Vector2i:
	return Vector2i(int(floor(point.x / gridSize)), int(floor(point.z / gridSize)))
