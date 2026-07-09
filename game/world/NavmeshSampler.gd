class_name NavmeshSampler

class Sample:
	var points: Array[Vector3]

class Params:
	var navigationMap: RID
	var navigationMesh: NavigationMesh
	var origin: Vector3
	var sampleSpacing: float
	var outputSpacing: float
	var aabb: AABB
	var maximumDistance: float
	var includeSurfaces: bool
	var includeEdges: bool

class SignalBox:
	signal done(sample: Sample)

static func CollectNavmeshPoints(
		actor: Actor,
		gridSize: float,
		oversample: float = 0.0,
		includeSurfaces: bool = true,
		includeEdges: bool = true
	):
	var currentMapRid = actor.navigator.agent.get_navigation_map()
	var currentRegionRid = NavigationServer3D.map_get_closest_point_owner(currentMapRid, actor.global_position)
	var region = NavmeshManager.Instance.GetRegion(currentRegionRid)
	var movementSpeed = actor.movementSpeedPerAction + oversample
	var boxSize = Vector3(movementSpeed, 0, movementSpeed)

	var params = Params.new()
	params.navigationMap = currentMapRid
	params.navigationMesh = region.navigation_mesh
	params.origin = actor.global_position
	params.sampleSpacing = gridSize
	params.outputSpacing = gridSize
	params.aabb = AABB(params.origin - boxSize, boxSize * 2)
	params.maximumDistance = movementSpeed
	params.includeSurfaces = includeSurfaces
	params.includeEdges = includeEdges

	var signalBox = SignalBox.new()
	WorkerThreadPool.add_task(func():
		var sample = RunCollectNavmeshPointsTask(params)
		signalBox.done.emit.call_deferred(sample)
	)
	var data: Sample = await signalBox.done
	return data

static func RunCollectNavmeshPointsTask(params: Params) -> Sample:
	var currentMapRid = params.navigationMap
	var currentRegionRid = NavigationServer3D.map_get_closest_point_owner(currentMapRid, params.origin)

	var maxDistSquared = pow(params.maximumDistance, 2)
	var rawSurfaces: Array[Vector3]
	var rawEdges: Array[Vector3]
	if params.includeSurfaces:
		rawSurfaces = sampleSurfacePoints(currentMapRid, params.aabb, params.outputSpacing / 4.0)
	if params.includeEdges:
		rawEdges = sampleEdgePoints(currentRegionRid, params.navigationMesh, params.outputSpacing)

	var buckets: Dictionary[Vector2i, Vector3]

	if params.includeSurfaces:
		var originPt = params.origin + Vector3(0, 0.01, 0)
		buckets[toCellCoordinates(originPt, params.outputSpacing)] = originPt

	insertBest(buckets, rawEdges, params.origin, maxDistSquared, params.outputSpacing)
	insertBest(buckets, rawSurfaces, params.origin, maxDistSquared, params.outputSpacing)
	var sample = Sample.new()
	for key: Vector2i in buckets:
		sample.points.push_back(buckets[key])
	return sample

static func insertBest(
		buckets: Dictionary[Vector2i, Vector3],
		points: Array[Vector3],
		origin: Vector3,
		maxDistSquared: float,
		cellSize: float
	):
	for point in points:
		if point.distance_squared_to(origin) > maxDistSquared:
			continue
		var key = toCellCoordinates(point, cellSize)
		if not buckets.has(key):
			buckets[key] = point
		elif isCloserToCenter(point, buckets[key], key, cellSize):
			buckets[key] = point

static func isCloserToCenter(candidate: Vector3, existing: Vector3, cell: Vector2i, cellSize: float) -> bool:
	var center = Vector2((cell.x + 0.5) * cellSize, (cell.y + 0.5) * cellSize)
	var dc = Vector2(candidate.x, candidate.z).distance_squared_to(center)
	var de = Vector2(existing.x, existing.z).distance_squared_to(center)
	return dc < de

static func sampleEdgePoints(region: RID, navMesh: NavigationMesh, spacing: float) -> Array[Vector3]:
	var verts = navMesh.get_vertices()
	var xform = NavigationServer3D.region_get_transform(region)

	# Count edge usage to find boundary edges
	var edge_count = {}
	for i in navMesh.get_polygon_count():
		var poly = navMesh.get_polygon(i)
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
			var cell = Vector3(ix * spacing, bounds.position.y, iz * spacing)
			var on_mesh = NavigationServer3D.map_get_closest_point(map_rid, cell)
			if Vector2(cell.x - on_mesh.x, cell.z - on_mesh.z).length() < spacing / 2.0:
				result.append(Vector3(on_mesh.x, 0.0, on_mesh.z))
	return result

static func toCellCoordinates(point: Vector3, gridSize: float) -> Vector2i:
	return Vector2i(int(floor(point.x / gridSize)), int(floor(point.z / gridSize)))
