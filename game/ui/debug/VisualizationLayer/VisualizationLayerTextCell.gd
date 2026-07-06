extends Label
class_name VisualizationLayerTextCell

var color = Color.WHITE
var worldPosition: Vector3

func SetMessage(message: String):
	text = message

func SetPosition(worldPoint: Vector3):
	worldPosition = worldPoint

func _process(_delta: float) -> void:
	global_position = get_viewport().get_camera_3d().unproject_position(worldPosition) - Vector2(size.x / 2, size.y)
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2(size.x / 2, size.y), 3.0, color)
