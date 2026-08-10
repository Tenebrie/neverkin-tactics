extends Node3D

func _ready() -> void:
	_generateEncounter()
	await get_tree().process_frame
	_startEncounter()

func _generateEncounter():
	const obstacleScene = preload("res://content/props/PropWallObstacleCover.tscn")
	const lowCoverScene = preload("res://content/props/PropWallLowCover.tscn")
	const highCoverScene = preload("res://content/props/PropWallHighCover.tscn")
	const fullCoverScene = preload("res://content/props/PropWallFullCover.tscn")

	const arenaHalfSize = 10.0
	const arenaGridSize = 0.2

	const gridCellCount = floori(arenaHalfSize / arenaGridSize) * 2 - 2

	var dataGrid: Array[Array[int]]

	#region Fixed walls
	var fixedWall = fullCoverScene.instantiate() as PropWall
	fixedWall.ObstacleWidth = 100
	fixedWall.position = Vector3(-9.9, -0.1, 0)
	fixedWall.rotate(Vector3.UP, deg_to_rad(90.0))
	add_child(fixedWall)
	fixedWall = fullCoverScene.instantiate() as PropWall
	fixedWall.ObstacleWidth = 100
	fixedWall.position = Vector3(9.9, -0.1, 0)
	fixedWall.rotate(Vector3.UP, deg_to_rad(90.0))
	add_child(fixedWall)
	fixedWall = fullCoverScene.instantiate() as PropWall
	fixedWall.ObstacleWidth = 99
	fixedWall.position = Vector3(0, -0.1, 9.9)
	add_child(fixedWall)
	fixedWall = fullCoverScene.instantiate() as PropWall
	fixedWall.ObstacleWidth = 99
	fixedWall.position = Vector3(0, -0.1, -9.9)
	add_child(fixedWall)
	#endregion

	# Generate the grid
	for x in gridCellCount:
		var row: Array[int] = []
		for y in gridCellCount:
			row.append(randi_range(0, 2000))
		dataGrid.append(row)

	# Populate the grid
	for x in gridCellCount:
		for y in gridCellCount:
			if dataGrid[x][y] >= 4:
				continue
			var propScene = obstacleScene
			if dataGrid[x][y] == 1:
				propScene = lowCoverScene
			elif dataGrid[x][y] == 2:
				propScene = highCoverScene
			elif dataGrid[x][y] == 3:
				propScene = fullCoverScene

			var spawnedProp = propScene.instantiate() as PropWall
			spawnedProp.ObstacleWidth = randi_range(4, 10)
			var rotateRandom = randi_range(0, 14)
			if rotateRandom <= 5:
				spawnedProp.rotate(Vector3.UP, 0.0)
			elif rotateRandom <= 10:
				spawnedProp.rotate(Vector3.UP, deg_to_rad(90.0))
			elif rotateRandom <= 12:
				spawnedProp.rotate(Vector3.UP, deg_to_rad(45.0))
			elif rotateRandom <= 14:
				spawnedProp.rotate(Vector3.UP, deg_to_rad(-45.0))

			add_child(spawnedProp)
			spawnedProp.position = Vector3(x * arenaGridSize - arenaHalfSize, -0.1, y * arenaGridSize - arenaHalfSize)
			spawnedProp.position += Vector3(0.3, 0, 0.3)


func _startEncounter():
	_populateSpawnGroups()


func _populateSpawnGroups():
	var spawnGroups = get_children().filter(func(child): return child is SpawnPointGroup)
	for group: SpawnPointGroup in spawnGroups:
		var points = group.spawnPoints
		if group.forcedFaction == Actor.Faction.Kin:
			assert(points.size() >= 3)
			points[0].spawn(preload("res://content/actors/Ivera/Ivera.tscn"))
			points[1].spawn(preload("res://content/actors/Kamilla/Kamilla.tscn"))
			points[2].spawn(preload("res://content/actors/Char/Char.tscn"))
			continue
		elif group.forcedFaction == Actor.Faction.Wolfpack:
			points[0].spawn(preload("res://content/actors/WolfpackBrawler/WolfpackBrawler.tscn"))
			points[1].spawn(preload("res://content/actors/WolfpackTrooper/WolfpackTrooper.tscn"))
			continue
		elif group.forcedFaction == Actor.Faction.None:
			continue
		Log.error("Faction %s can't be spawned."%group.forcedFaction)


func _clearEncounter():
	for actor in Actor.Repository.All.asList():
		actor.Destroy()
	for actor in Actor.Repository.Destroyed.asList():
		actor.finalize()
	for spawnPoint in SpawnPointGroup.All:
		spawnPoint.queue_free()
	SnapshotManager.PruneAllSnapshots()


func _onGenerateNewEncounter() -> void:
	_clearEncounter()
	_generateEncounter()
	_startEncounter()
	SnapshotManager.CreateSnapshot()
