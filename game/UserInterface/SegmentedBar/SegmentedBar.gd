@tool
extends Control
class_name SegmentedBar

var _value: int = 8
var _maxValue: int = 10
var _inhumanValue: int = 3
var _threatValue: int = 2
var _backgroundColor: Color = Color(0.102, 0.102, 0.102, 0.302)
var _fillColor: Color = Color.DARK_GREEN
var _inhumanColor: Color = Color.DARK_MAGENTA
var _threatColor: Color = Color.DARK_RED

@export var Value: int = 0:
	get: return _value
	set(value):
		_value = value
		render()

@export var MaxValue: int = 10:
	get: return _maxValue
	set(value):
		_maxValue = value
		render()

@export var InhumanValue: int = 0:
	get: return _inhumanValue
	set(value):
		_inhumanValue = value
		render()

@export var ThreatValue: int = 0:
	get: return _threatValue
	set(value):
		_threatValue = value
		render()

@export var BackgroundColor: Color = Color(0.102, 0.102, 0.102, 0.302):
	get: return _backgroundColor
	set(value):
		_backgroundColor = value
		render()

@export var FillColor: Color = Color.DARK_GREEN:
	get: return _fillColor
	set(value):
		_fillColor = value
		render()

@export var InhumanColor: Color = Color.DARK_MAGENTA:
	get: return _inhumanColor
	set(value):
		_inhumanColor = value
		render()

@export var ThreatColor: Color = Color.DARK_RED:
	get: return _threatColor
	set(value):
		_threatColor = value
		render()

@onready var isReady: bool = true
@onready var backgroundBar: ProgressBar = $BackgroundBar
@onready var valueBar: ProgressBar = $ValueBar
@onready var inhumanBar: ProgressBar = $InhumanBar
@onready var threatBar: ProgressBar = $ThreatBar
@onready var overlay: Control = $BarsOverlay

func _ready() -> void:
	overlay.draw.connect(drawLines)
	resized.connect(render)
	render()

func render():
	if not isReady:
		return

	valueBar.value = _value
	valueBar.max_value = _maxValue

	inhumanBar.value = min(_value, _inhumanValue)
	inhumanBar.max_value = _maxValue

	var unitWidth = size.x / _maxValue
	threatBar.max_value = _maxValue
	threatBar.value = _threatValue
	threatBar.position.x = (_value - _maxValue) * unitWidth

	var bgStylebox: StyleBoxFlat = backgroundBar.get_theme_stylebox("background")
	bgStylebox.bg_color = _backgroundColor
	backgroundBar.add_theme_stylebox_override("background", bgStylebox)

	var valueStylebox: StyleBoxFlat = valueBar.get_theme_stylebox("fill")
	valueStylebox.bg_color = _fillColor
	var rightRadius = 6 if _value == _maxValue else 0
	valueStylebox.corner_radius_top_right = rightRadius
	valueStylebox.corner_radius_bottom_right = rightRadius
	valueBar.add_theme_stylebox_override("fill", valueStylebox)

	var threatStylebox: StyleBoxFlat = threatBar.get_theme_stylebox("fill")
	threatStylebox.corner_radius_top_right = rightRadius
	threatStylebox.corner_radius_bottom_right = rightRadius
	var leftRadius = 6 if _value - _threatValue <= 0 else 0
	threatStylebox.bg_color = _threatColor
	threatStylebox.corner_radius_top_left = leftRadius
	threatStylebox.corner_radius_bottom_left = leftRadius
	threatBar.add_theme_stylebox_override("fill", threatStylebox)

	var inhumanStylebox: StyleBoxFlat = inhumanBar.get_theme_stylebox("fill")
	var inhumanRadius = 6 if _inhumanValue >= _maxValue else 0
	inhumanStylebox.bg_color = _inhumanColor
	inhumanStylebox.corner_radius_top_right = inhumanRadius
	inhumanStylebox.corner_radius_bottom_right = inhumanRadius
	inhumanBar.add_theme_stylebox_override("fill", inhumanStylebox)

	overlay.queue_redraw()

func drawLines():
	var tickWidth = overlay.size.x / float(MaxValue)
	var tickHeight = overlay.size.y

	for i in range(1, MaxValue):
		var pos = roundi(tickWidth * i)
		overlay.draw_line(Vector2(pos, 0.5), Vector2(pos, tickHeight - 0.5), Color(0.0, 0, 0, 0.5), 1, true)
