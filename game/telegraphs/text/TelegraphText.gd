extends CanvasLayer
class_name TelegraphText

@onready var parent: Telegraph = get_parent()

@onready var label: Label = %Label

var text: String = "":
	set(v):
		text = v
		if is_node_ready():
			label.text = v
var fontColor: Color = Color.WHITE:
	set(v):
		fontColor = v
		if is_node_ready():
			label.label_settings.font_color = v

func _ready():
	text = text
	fontColor = fontColor

func SetText(text: String):
	label.text = text

var size: Vector2:
	get:
		return label.size

func _process(_d):
	fontColor = parent.Tint
