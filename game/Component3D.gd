extends Node3D
class_name Component3D

var parent: Actor

func _init():
	tree_entered.connect(func():
		parent = get_parent()
		get_parent().ready.connect(_parentReady, CONNECT_ONE_SHOT)
	, CONNECT_ONE_SHOT)

func _parentReady():
	pass

func createChild(object: Object):
	if object is GDScript:
		object = object.new()
	add_child(object)
	return object
