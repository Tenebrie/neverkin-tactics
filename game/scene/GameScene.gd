extends Node3D
class_name GameScene

func _exit_tree() -> void:
	NodeSignalBus.ClearAll()
