@tool
extends Node3D
class_name SpawnPointGroup

@export var forcedFaction: Actor.Faction = Actor.Faction.None

var spawnPoints: Array[SpawnPoint]:
	get:
		var spawnPoints: Array[SpawnPoint]
		for child in get_children():
			if child is SpawnPoint:
				spawnPoints.push_back(child)
		return spawnPoints

func _ready() -> void:
	All.push_back(self)

func _exit_tree() -> void:
	All.remove_at(All.find(self))

static var All: Array[SpawnPointGroup]
