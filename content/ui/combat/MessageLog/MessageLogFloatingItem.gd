extends Label
class_name MessageLogFloatingItem

var followCamera = false
var worldPosition: Vector3
var screenOffset: Vector2

func SetMessage(message: String):
	text = message

func _ready():
	var tween = create_tween()
	tween.set_parallel()
	if followCamera:
		tween.tween_property(self, "screenOffset", Vector2(screenOffset.x + randf_range(-15, 15), screenOffset.y - 50.0 + randf_range(-15, 25)), 1.0).set_ease(Tween.EASE_IN_OUT)
	else:
		tween.tween_property(self, "position", Vector2(position.x + randf_range(-15, 15), position.y - 50.0 + randf_range(-15, 25)), 1.0).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "self_modulate", Color.TRANSPARENT, 0.5).set_delay(0.5)
	await get_tree().create_timer(1).timeout
	queue_free()

func _process(_d):
	if followCamera:
		global_position = get_viewport().get_camera_3d().unproject_position(worldPosition) + screenOffset
