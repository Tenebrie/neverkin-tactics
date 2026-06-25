extends Node
class_name Component

@onready var parent: Actor = get_parent()

func createChild(object: Object):
	if object is GDScript:
		object = object.new()
	add_child(object)
	return object
