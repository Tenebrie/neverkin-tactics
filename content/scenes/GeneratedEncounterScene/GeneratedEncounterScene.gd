extends Node3D

@onready var encounterControls: EncounterControls = $EncounterControls

var currentGenerator: ArenaGenerator

func _ready() -> void:
	_generateEncounter()
	_startEncounter.call_deferred()

func _generateEncounter():
	currentGenerator = ArenaGenerator.new()
	currentGenerator.minArenaSize = encounterControls.arenaSize
	currentGenerator.maxArenaSize = encounterControls.arenaSize
	currentGenerator.factionsToSpawn = encounterControls.getFactionsToSpawn()
	currentGenerator.generate($GeometryParent)

func _startEncounter():
	currentGenerator.spawnActors()

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
