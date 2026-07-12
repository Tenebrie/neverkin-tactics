## Mind control helper
##
## Assigns the given faction to all Actor children
extends Node3D
class_name MindControlNode

@export var faction: Actor.Faction

func _ready():
	for child in get_children():
		if child is not Actor actor:
			continue
		if not actor.buffs:
			continue
		var buff = BuffMindControl.new()
		buff.Duration = INF
		buff.faction = faction
		actor.buffs.Add(buff)
