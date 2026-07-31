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
