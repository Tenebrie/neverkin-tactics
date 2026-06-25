@tool
extends Camera3D

func _ready() -> void:
	if Engine.is_editor_hint():
		queue_free()

func _process(delta):
	look_at(Vector3.ZERO, Vector3.UP)
