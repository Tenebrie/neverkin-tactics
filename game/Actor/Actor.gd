class_name Actor
extends CharacterBody3D

@onready var stats: ActorStats = $ActorStats
@onready var actions: ActorActions = $ActorActions
@onready var navigator: ActorNavigator = $ActorNavigator
@onready var targeting: ActorTargeting = $ActorTargeting

func createChild(object: Object):
	if object is GDScript:
		object = object.new()
	add_child(object)
	return object
