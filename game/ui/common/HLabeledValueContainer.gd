@tool
extends HBoxContainer
class_name HLabeledValueContainer

@export var label = "Label":
	set(v):
		label = v
		update()
@export var label_color = Color.WHITE:
	set(v):
		label_color = v
		update()

@export var text = "Text":
	set(v):
		text = v
		update()
@export var text_color = Color.WHITE:
	set(v):
		text_color = v
		update()

var _labelControl: Label
var _valueControl: Label

func _ready():
	_labelControl = Label.new()
	_valueControl = Label.new()
	_labelControl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_labelControl)
	add_child(_valueControl)
	update()

func update():
	if not is_node_ready():
		return
	_labelControl.text = label
	_valueControl.text = text
	_labelControl.add_theme_color_override("font_color", label_color)
	_valueControl.add_theme_color_override("font_color", text_color)
