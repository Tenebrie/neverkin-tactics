extends Node3D

func _ready() -> void:
	_generateEncounter()
	_startEncounter()

func _generateEncounter():
	pass


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
			continue
		elif group.forcedFaction == Actor.Faction.None:
			continue
		Log.error("Faction %s can't be spawned."%group.forcedFaction)


func _clearEncounter():
	for actor in Actor.Repository.All.asList():
		actor.Destroy()
	for actor in Actor.Repository.Destroyed.asList():
		actor.finalize()


func _onEncounterRestarted() -> void:
	#SnapshotManager.RestoreSnapshot(encounterStartSnapshot)
	pass
