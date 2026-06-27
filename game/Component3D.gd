extends Node3D
class_name Component3D

@onready var parent: Actor = get_parent()

func createChild(object: Object):
	if object is GDScript:
		object = object.new()
	add_child(object)
	return object
