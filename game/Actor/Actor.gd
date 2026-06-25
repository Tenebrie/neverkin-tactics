class_name Actor
extends CharacterBody3D

@onready var navigator: ActorNavigator = $ActorNavigator
@onready var actions: ActorActions = $ActorActions

func createChild(object: Object):
	if object is GDScript:
		object = object.new()
	add_child(object)
	return object
