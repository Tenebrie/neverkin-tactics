extends Node
class_name Component

var Parent: Actor

func _init():
	tree_entered.connect(func():
		Parent = get_parent()
		get_parent().ready.connect(_parentReady, CONNECT_ONE_SHOT)
	, CONNECT_ONE_SHOT)

func _parentReady():
	pass

func createChild(object: Object):
	if object is GDScript:
		object = object.new()
	add_child(object)
	return object
