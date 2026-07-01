extends Control
class_name CursorUserInterface

@onready var distLabel: Label = $%Label
@onready var costLabel: Label = $%Label2

func _process(_delta):
	global_position = get_global_mouse_position() - Vector2($VBoxContainer.size.x / 2, 4)

func ShowActionPointCost(value: float, dist: float):
	$%Label2.text = "%.2fm"%[dist]
	$%Label.text = "%d AP"%[value]
	$%Label.visible = true
	$%Label2.visible = true
	distLabel.label_settings.outline_color = GetActionPointColor(roundi(value))
	costLabel.label_settings.outline_color = GetActionPointColor(roundi(value))

func HideActionPointCost():
	$%Label.visible = false
	$%Label2.visible = false

func GetActionPointColor(ap: int) -> Color:
	var segmentColors: Array[Color] = [
		Color(0.18, 0.80, 0.25, 0.6),  # Green  - this turn
		Color(0.95, 0.85, 0.15, 0.6),  # Yellow - next turn
		Color(0.90, 0.25, 0.20, 0.6),  # Red    - two turns out
		Color(0.60, 0.15, 0.15, 0.5),  # Dark red - even further
	]
	if ap < segmentColors.size():
		return segmentColors[ap]
	return Color(0.40, 0.05, 0.05, 0.5)
