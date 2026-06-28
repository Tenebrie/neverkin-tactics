extends Control
class_name CursorUserInterface

func _process(_delta):
	global_position = get_global_mouse_position() - Vector2($Control.size.x / 2, $Control.size.y)

func ShowActionPointCost(value: float):
	$%Label.text = "AP: %d" % value
	$%Label.visible = true

func HideActionPointCost():
	$%Label.visible = false
