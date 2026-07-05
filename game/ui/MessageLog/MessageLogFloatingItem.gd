extends Label
class_name MessageLogFloatingItem

func SetMessage(message: String):
	text = message

func _ready():
	var tween = create_tween()
	tween.set_parallel()
	tween.tween_property(self, "position", Vector2(position.x + randf_range(-25, 25), position.y - 50.0 + randf_range(-15, 25)), 1.0).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "self_modulate", Color.TRANSPARENT, 0.5).set_delay(0.5)
	await get_tree().create_timer(1).timeout
	queue_free()
