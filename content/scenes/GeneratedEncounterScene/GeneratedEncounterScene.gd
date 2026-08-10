extends Node3D

const FactionRosters = {
	Actor.Faction.Kin: [
		preload("res://content/actors/Ivera/Ivera.tscn"),
		preload("res://content/actors/Kamilla/Kamilla.tscn"),
		preload("res://content/actors/Char/Char.tscn"),
	],
	Actor.Faction.Wolfpack: [
		preload("res://content/actors/WolfpackBrawler/WolfpackBrawler.tscn"),
		preload("res://content/actors/WolfpackTrooper/WolfpackTrooper.tscn"),
		preload("res://content/actors/WolfpackTrooper/WolfpackTrooper.tscn"),
	],
}

const EncounterControls = preload("./EncounterControls/EncounterControls.gd")
@onready var encounterControls: EncounterControls = $EncounterControls

func _ready() -> void:
	_generateEncounter()
	await get_tree().process_frame
	_startEncounter()

func _generateEncounter():
	var currentGenerator = ArenaGenerator.new()
	currentGenerator.minArenaSize = encounterControls.arenaSize
	currentGenerator.maxArenaSize = encounterControls.arenaSize
	currentGenerator.generate($GeometryParent)

func _startEncounter():
	_populateSpawnGroups()

func _populateSpawnGroups():
	for group in SpawnPointGroup.All:
		if group.forcedFaction == Actor.Faction.None:
			continue
		if not FactionRosters.has(group.forcedFaction):
			Log.error("Faction %s can't be spawned." % group.forcedFaction)
			continue
		var roster = FactionRosters[group.forcedFaction]
		var points = group.spawnPoints
		assert(points.size() >= roster.size())
		for i in roster.size():
			points[i].spawn(roster[i])

func _clearEncounter():
	for actor in Actor.Repository.All.asList():
		actor.Destroy()
	for actor in Actor.Repository.Destroyed.asList():
		actor.finalize()
	for child in $GeometryParent.get_children():
		child.free()
	SnapshotManager.PruneAllSnapshots()

func _onGenerateNewEncounter() -> void:
	_clearEncounter()
	_generateEncounter()
	_startEncounter()
	SnapshotManager.CreateSnapshot()
