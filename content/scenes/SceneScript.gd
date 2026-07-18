extends Node


func _ready() -> void:
	var children := get_children()
	for child in children:
		if child is Sprite2D:
			child.hide()
