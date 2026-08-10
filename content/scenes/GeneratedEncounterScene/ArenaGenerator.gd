class_name ArenaGenerator

enum PieceKind { FullWall, HighWall, HighCrate, LowBar, ObstacleCrate }

const pieceScenes = {
	PieceKind.FullWall: preload("res://content/props/PropWallFullCover.tscn"),
	PieceKind.HighWall: preload("res://content/props/PropWallHighCover.tscn"),
	PieceKind.HighCrate: preload("res://content/props/PropWallHighCover.tscn"),
	PieceKind.LowBar: preload("res://content/props/PropWallLowCover.tscn"),
	PieceKind.ObstacleCrate: preload("res://content/props/PropWallObstacleCover.tscn"),
}
const floorTexture = preload("res://addons/prototype-textures/dark/texture_08.png")

const cellSize = 1.0
const segmentsPerCell = 5
const floorHeight = -0.1
const spawnZoneDepthCells = 3
const maxLayoutAttempts = 20

var minArenaSize = Vector2i(8, 14)
var maxArenaSize = Vector2i(8, 14)
var factionsToSpawn: Array[EncounterControls.FactionToSpawn]
var spawnGroups: Array[SpawnPointGroup]

class CoverPiece:
	var kind: int
	var cellRect: Rect2i
	var rotationDegrees: float

class ArenaLayout:
	var widthCells: int
	var depthCells: int
	var isVertical: bool
	var pieces: Array[CoverPiece] = []
	var occupiedCells = {}
	var reservedCells = {}
	var spawnCellsByFaction = {}

func generate(geometryParent: Node3D) -> void:
	var layout = _createValidatedLayout()
	_buildArena(layout, geometryParent)

func _createValidatedLayout() -> ArenaLayout:
	for attempt in maxLayoutAttempts:
		var layout = _createLayout()
		if _spawnCellsConnected(layout):
			return layout
	var openArena = _createLayout()
	openArena.pieces.clear()
	return openArena

func _createLayout() -> ArenaLayout:
	var layout = ArenaLayout.new()
	var sizeRollA = randi_range(minArenaSize.x, maxArenaSize.x)
	var sizeRollB = randi_range(minArenaSize.y, maxArenaSize.y)
	layout.widthCells = maxi(sizeRollA, sizeRollB)
	layout.depthCells = mini(sizeRollA, sizeRollB)
	layout.isVertical = sizeRollA < sizeRollB
	_reserveSpawnZones(layout)
	_placeCenterWall(layout)
	_placeWallRuns(layout)
	_placeCoverClusters(layout)
	_placeScatteredCover(layout)
	_chooseSpawnCells(layout)
	return layout

func _spawnZoneRect(layout: ArenaLayout, westSide: bool) -> Rect2i:
	var zoneHeight = clampi(layout.depthCells - 8, 4, 10)
	var originY = (layout.depthCells - zoneHeight) / 2.0
	var originX = 1 if westSide else layout.widthCells - 1 - spawnZoneDepthCells
	return Rect2i(originX, int(originY), spawnZoneDepthCells, zoneHeight)

func _reserveSpawnZones(layout: ArenaLayout) -> void:
	for zone in [_spawnZoneRect(layout, true), _spawnZoneRect(layout, false)]:
		for cell in _cellsInRect(zone.grow(1)):
			layout.reservedCells[cell] = true

func _placeCenterWall(layout: ArenaLayout) -> void:
	var lengthCells = 3 + 2 * randi_range(0, 1)
	var kind = PieceKind.HighWall if randf() < 0.7 else PieceKind.FullWall
	var origin = Vector2(layout.widthCells / 2.0, (layout.depthCells - lengthCells) / 2.0)
	_tryPlacePiece(layout, kind, Rect2i(origin, Vector2i(1, lengthCells)), 90.0, false)

func _placeWallRuns(layout: ArenaLayout) -> void:
	var pairBudget = layout.widthCells * layout.depthCells / 100.0
	var placed = 0
	for attempt in 200:
		if placed >= pairBudget:
			break
		var lengthCells = randi_range(2, 4)
		var acrossSpawnAxis = randf() < 0.65
		var size = Vector2i(1, lengthCells) if acrossSpawnAxis else Vector2i(lengthCells, 1)
		var rotation = 90.0 if acrossSpawnAxis else 0.0
		var kind = PieceKind.HighWall if randf() < 0.7 else PieceKind.FullWall
		if _tryPlacePiece(layout, kind, Rect2i(_randomOrigin(layout, size), size), rotation):
			placed += 1

func _placeCoverClusters(layout: ArenaLayout) -> void:
	var pairBudget = layout.widthCells * layout.depthCells / 60.0
	var placed = 0
	for attempt in 300:
		if placed >= pairBudget:
			break
		if _tryPlaceCluster(layout):
			placed += 1

func _tryPlaceCluster(layout: ArenaLayout) -> bool:
	var anchor = _randomOrigin(layout, Vector2i.ONE)
	var offsets: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
	offsets.shuffle()
	var members = [[anchor, PieceKind.HighCrate, 90.0 * randi_range(0, 1)]]
	for i in randi_range(1, 2):
		var offset = offsets[i]
		var barKind = PieceKind.LowBar if randf() < 0.75 else PieceKind.ObstacleCrate
		var barRotation = 90.0 if offset.x != 0 else 0.0
		members.append([anchor + offset, barKind, barRotation])

	var minCell = anchor
	var maxCell = anchor
	for member in members:
		minCell = minCell.min(member[0])
		maxCell = maxCell.max(member[0])
	var bounds = Rect2i(minCell, maxCell - minCell + Vector2i.ONE)

	if not _canPlaceRect(layout, bounds):
		return false
	var mirrorBounds = _mirrorRect(layout, bounds)
	if mirrorBounds.grow(1).intersects(bounds):
		return false
	if not _canPlaceRect(layout, mirrorBounds):
		return false

	for member in members:
		_commitPiece(layout, member[1], Rect2i(member[0], Vector2i.ONE), member[2])
		_commitPiece(layout, member[1], Rect2i(_mirrorCell(layout, member[0]), Vector2i.ONE), member[2])
	return true

func _placeScatteredCover(layout: ArenaLayout) -> void:
	var pairBudget = layout.widthCells * layout.depthCells / 70.0
	var placed = 0
	for attempt in 200:
		if placed >= pairBudget:
			break
		var kind = PieceKind.LowBar if randf() < 0.7 else PieceKind.ObstacleCrate
		var rotation: float = [0.0, 90.0, 45.0, -45.0].pick_random()
		if _tryPlacePiece(layout, kind, Rect2i(_randomOrigin(layout, Vector2i.ONE), Vector2i.ONE), rotation):
			placed += 1

func _tryPlacePiece(layout: ArenaLayout, kind: int, rect: Rect2i, rotationDegrees: float, mirrored = true) -> bool:
	if not _canPlaceRect(layout, rect):
		return false
	if mirrored:
		var mirrorRect = _mirrorRect(layout, rect)
		if mirrorRect.grow(1).intersects(rect):
			return false
		if not _canPlaceRect(layout, mirrorRect):
			return false
		_commitPiece(layout, kind, mirrorRect, rotationDegrees)
	_commitPiece(layout, kind, rect, rotationDegrees)
	return true

func _canPlaceRect(layout: ArenaLayout, rect: Rect2i) -> bool:
	var interior = Rect2i(Vector2i.ONE, Vector2i(layout.widthCells - 2, layout.depthCells - 2))
	if not interior.encloses(rect):
		return false
	for cell in _cellsInRect(rect.grow(1)):
		if layout.occupiedCells.has(cell):
			return false
	for cell in _cellsInRect(rect):
		if layout.reservedCells.has(cell):
			return false
	return true

func _commitPiece(layout: ArenaLayout, kind: int, rect: Rect2i, rotationDegrees: float) -> void:
	var piece = CoverPiece.new()
	piece.kind = kind
	piece.cellRect = rect
	piece.rotationDegrees = rotationDegrees
	layout.pieces.append(piece)
	for cell in _cellsInRect(rect):
		layout.occupiedCells[cell] = true

func _chooseSpawnCells(layout: ArenaLayout) -> void:
	var sides = factionsToSpawn.duplicate()
	if randf() < 0.5:
		sides.reverse()
	var maxActorCount = 0
	for side in sides:
		maxActorCount = maxi(maxActorCount, side.actors.size())
	var westCells = _pickSpawnCells(_spawnZoneRect(layout, true), maxActorCount)
	var eastCells: Array[Vector2i] = []
	for cell in westCells:
		eastCells.append(_mirrorCell(layout, cell))
	layout.spawnCellsByFaction[sides[0].faction] = westCells.slice(0, sides[0].actors.size())
	layout.spawnCellsByFaction[sides[1].faction] = eastCells.slice(0, sides[1].actors.size())

func _pickSpawnCells(zone: Rect2i, count: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var attempts = 0
	while cells.size() < count and attempts < 200:
		attempts += 1
		var candidate = Vector2i(
			randi_range(zone.position.x, zone.end.x - 1),
			randi_range(zone.position.y, zone.end.y - 1)
		)
		var minSpacing = 2 if attempts < 100 else 1
		var farEnough = cells.all(func(existing: Vector2i) -> bool:
			return maxi(absi(existing.x - candidate.x), absi(existing.y - candidate.y)) >= minSpacing
		)
		if farEnough:
			cells.append(candidate)
	return cells

func _spawnCellsConnected(layout: ArenaLayout) -> bool:
	var allSpawnCells: Array[Vector2i] = []
	for cells in layout.spawnCellsByFaction.values():
		allSpawnCells.append_array(cells)
	if allSpawnCells.is_empty():
		return true

	var visited = {allSpawnCells[0]: true}
	var frontier: Array[Vector2i] = [allSpawnCells[0]]
	while not frontier.is_empty():
		var cell = frontier.pop_back()
		for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = cell + offset
			if visited.has(next) or layout.occupiedCells.has(next):
				continue
			if next.x < 0 or next.y < 0 or next.x >= layout.widthCells or next.y >= layout.depthCells:
				continue
			visited[next] = true
			frontier.push_back(next)
	return allSpawnCells.all(func(cell: Vector2i) -> bool: return visited.has(cell))

func _mirrorCell(layout: ArenaLayout, cell: Vector2i) -> Vector2i:
	return Vector2i(layout.widthCells - 1 - cell.x, layout.depthCells - 1 - cell.y)

func _mirrorRect(layout: ArenaLayout, rect: Rect2i) -> Rect2i:
	var farCorner = rect.position + rect.size - Vector2i.ONE
	return Rect2i(_mirrorCell(layout, farCorner), rect.size)

func _randomOrigin(layout: ArenaLayout, size: Vector2i) -> Vector2i:
	return Vector2i(
		randi_range(1, layout.widthCells - 1 - size.x),
		randi_range(1, layout.depthCells - 1 - size.y)
	)

func _cellsInRect(rect: Rect2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for x in range(rect.position.x, rect.end.x):
		for y in range(rect.position.y, rect.end.y):
			cells.append(Vector2i(x, y))
	return cells

func _cellCenterWorld(layout: ArenaLayout, cell: Vector2i) -> Vector2:
	return Vector2(
		(cell.x + 0.5) * cellSize - layout.widthCells * cellSize * 0.5,
		(cell.y + 0.5) * cellSize - layout.depthCells * cellSize * 0.5
	)

func _rectCenterWorld(layout: ArenaLayout, rect: Rect2i) -> Vector2:
	return Vector2(
		(rect.position.x + rect.size.x * 0.5) * cellSize - layout.widthCells * cellSize * 0.5,
		(rect.position.y + rect.size.y * 0.5) * cellSize - layout.depthCells * cellSize * 0.5
	)

func _buildArena(layout: ArenaLayout, geometryParent: Node3D) -> void:
	var container = Node3D.new()
	container.name = "GeneratedArena"
	geometryParent.add_child(container)
	if layout.isVertical:
		container.rotation_degrees = Vector3(0.0, 90.0, 0.0)
	_buildFloor(container, layout)
	_buildPerimeter(container, layout)
	for piece in layout.pieces:
		_buildPiece(container, piece, layout)
	_buildSpawnGroups(container, layout)
	NavmeshManager.Instance.rebakeNavmeshForCurrentActor()

func _buildFloor(parent: Node3D, layout: ArenaLayout) -> void:
	var arenaSize = Vector2(layout.widthCells * cellSize, layout.depthCells * cellSize)

	var material = StandardMaterial3D.new()
	material.albedo_texture = floorTexture
	material.uv1_scale = Vector3(arenaSize.x, arenaSize.y, 1)
	var plane = PlaneMesh.new()
	plane.size = arenaSize
	plane.material = material
	var floorMesh = MeshInstance3D.new()
	floorMesh.mesh = plane
	floorMesh.position = Vector3(0, floorHeight, 0)
	parent.add_child(floorMesh)

	var box = BoxShape3D.new()
	box.size = Vector3(arenaSize.x, 0.01, arenaSize.y)
	var shape = CollisionShape3D.new()
	shape.shape = box
	shape.position = Vector3(0, floorHeight, 0)
	var floorBody = StaticBody3D.new()
	floorBody.add_child(shape)
	parent.add_child(floorBody)

func _buildPerimeter(parent: Node3D, layout: ArenaLayout) -> void:
	var halfWidth = layout.widthCells * cellSize * 0.5
	var halfDepth = layout.depthCells * cellSize * 0.5
	var inset = 0.1
	var widthSegments = layout.widthCells * segmentsPerCell
	var depthSegments = layout.depthCells * segmentsPerCell - 2
	_buildPerimeterWall(parent, Vector3(0, floorHeight, halfDepth - inset), widthSegments, 0.0)
	_buildPerimeterWall(parent, Vector3(0, floorHeight, -halfDepth + inset), widthSegments, 0.0)
	_buildPerimeterWall(parent, Vector3(halfWidth - inset, floorHeight, 0), depthSegments, 90.0)
	_buildPerimeterWall(parent, Vector3(-halfWidth + inset, floorHeight, 0), depthSegments, 90.0)

func _buildPerimeterWall(parent: Node3D, position: Vector3, segmentCount: int, rotationDegrees: float) -> void:
	var wall = pieceScenes[PieceKind.FullWall].instantiate() as PropWall
	wall.ObstacleWidth = segmentCount
	wall.rotate(Vector3.UP, deg_to_rad(rotationDegrees))
	wall.position = position
	parent.add_child(wall)

func _buildPiece(parent: Node3D, piece: CoverPiece, layout: ArenaLayout) -> void:
	var wall = pieceScenes[piece.kind].instantiate() as PropWall
	var lengthCells = maxi(piece.cellRect.size.x, piece.cellRect.size.y)
	match piece.kind:
		PieceKind.FullWall, PieceKind.HighWall:
			wall.ObstacleWidth = lengthCells * segmentsPerCell - 2
			wall.ObstacleDepth = 1
		PieceKind.HighCrate, PieceKind.ObstacleCrate:
			wall.ObstacleWidth = randi_range(3, 4)
			wall.ObstacleDepth = randi_range(3, 4)
		PieceKind.LowBar:
			wall.ObstacleWidth = 4
			wall.ObstacleDepth = 2
	wall.rotate(Vector3.UP, deg_to_rad(piece.rotationDegrees))
	var center = _rectCenterWorld(layout, piece.cellRect)
	wall.position = Vector3(center.x, floorHeight, center.y)
	parent.add_child(wall)

func _buildSpawnGroups(parent: Node3D, layout: ArenaLayout) -> void:
	for faction in layout.spawnCellsByFaction:
		var group = SpawnPointGroup.new()
		group.forcedFaction = faction
		parent.add_child(group)
		spawnGroups.push_back(group)
		for cell in layout.spawnCellsByFaction[faction]:
			var point = SpawnPoint.new()
			group.add_child(point)
			var world = _cellCenterWorld(layout, cell)
			point.position = Vector3(world.x, 0, world.y)

func spawnActors() -> void:
	for factionToSpawn in factionsToSpawn:
		for group in spawnGroups:
			if group.forcedFaction != factionToSpawn.faction:
				continue
			var points = group.spawnPoints
			for i in mini(points.size(), factionToSpawn.actors.size()):
				points[i].spawn(factionToSpawn.actors[i])
