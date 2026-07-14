extends Control
class_name SegmentedBar

@export var Value = 8:
	set(v): Value = v; queue_redraw()

@export var MaxValue = 10:
	set(v): MaxValue = max(1, v); queue_redraw()

@export var InhumanValue = 3:
	set(v): InhumanValue = v; queue_redraw()

@export var ThreatValue = 2:
	set(v): ThreatValue = v; queue_redraw()

@export var PromiseValue = 1:
	set(v): PromiseValue = v; queue_redraw()

@export var CornerRadius = 6:
	set(v): CornerRadius = v; queue_redraw()

@export var GhostDelay = 0.25

@export var GhostDuration = 0.4

@export var BackgroundColor = Color(0.102, 0.102, 0.102, 0.302):
	set(v): BackgroundColor = v; queue_redraw()

@export var FillColor = Color.DARK_GREEN:
	set(v): FillColor = v; queue_redraw()

@export var InhumanColor = Color.DARK_MAGENTA:
	set(v): InhumanColor = v; queue_redraw()

@export var ThreatColor = Color.DARK_RED:
	set(v): ThreatColor = v; queue_redraw()

@export var PromiseColor = Color(0.85, 0.78, 0.55).darkened(0.3):
	set(v): PromiseColor = v; queue_redraw()

@export var GhostColor = Color(0.85, 0.78, 0.55):
	set(v): GhostColor = v; queue_redraw()

@export var TickColor = Color(0, 0, 0, 0.6):
	set(v): TickColor = v; queue_redraw()

@export var MediumTickColor = Color(0, 0, 0, 0.7):
	set(v): MediumTickColor = v; queue_redraw()

var _animValue: float = 0.0
var _ghostDelayLeft: float = 0.0
var _ghostTimeLeft: float = 0.0
var _lastValue: int = 0

func _ready():
	_lastValue = clampi(Value, 0, MaxValue)
	_animValue = _lastValue

func _notification(what: int):
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func _process(delta: float):
	var target = clampi(Value, 0, MaxValue)
	if target != _lastValue:
		_ghostTimeLeft = GhostDuration
		if target < _lastValue:
			_ghostDelayLeft = GhostDelay
	_lastValue = target

	if _animValue == target:
		return
	if _animValue > target and _ghostDelayLeft > 0.0:
		_ghostDelayLeft -= delta
		return

	if _ghostTimeLeft <= delta:
		_ghostTimeLeft = 0.0
		_animValue = target
	else:
		_animValue = move_toward(_animValue, target, absf(_animValue - target) / _ghostTimeLeft * delta)
		_ghostTimeLeft -= delta
	queue_redraw()

func makeBox(color: Color, topLeft: int, topRight: int, bottomLeft: int, bottomRight: int) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = color
	sb.corner_radius_top_left = topLeft
	sb.corner_radius_top_right = topRight
	sb.corner_radius_bottom_left = bottomLeft
	sb.corner_radius_bottom_right = bottomRight
	return sb

func _draw():
	var full = Rect2(Vector2.ZERO, size)
	var r = CornerRadius
	var unit = size.x / float(MaxValue)

	makeBox(BackgroundColor, r, r, r, r).draw(get_canvas_item(), full)

	var target = clampi(Value, 0, MaxValue)
	var anim = clampf(_animValue, 0.0, MaxValue)
	var value = minf(anim, target)
	var ghost = maxf(anim, target)
	var promise = clampf(minf(PromiseValue, MaxValue - value), 0.0, MaxValue)
	var threat = clampf(minf(ThreatValue, value), 0.0, MaxValue)
	var inhuman = clampf(minf(InhumanValue, value), 0.0, MaxValue)

	if ghost > value:
		var right_r = r if is_equal_approx(ghost, float(MaxValue)) else 0
		var box = makeBox(GhostColor, r, right_r, r, right_r)
		box.draw(get_canvas_item(), Rect2(0, 0, unit * ghost, size.y))

	if value > 0:
		var drawnValue = value - threat
		var right_r = r if drawnValue == MaxValue else 0
		var box = makeBox(FillColor, r, right_r, r, right_r)
		box.draw(get_canvas_item(), Rect2(0, 0, unit * drawnValue, size.y))

	if inhuman > 0:
		var right_r = r if inhuman == MaxValue else 0
		var box = makeBox(InhumanColor, r, right_r, r, right_r)
		var drawnValue = minf(inhuman, value - threat)
		box.draw(get_canvas_item(), Rect2(0, 0, unit * drawnValue, size.y))

	if promise > 0:
		var x = unit * value
		var w = unit * promise
		var right_r = r if value + promise >= MaxValue else 0
		var box = makeBox(PromiseColor, 0, right_r, 0, right_r)
		box.draw(get_canvas_item(), Rect2(x, 0, w, size.y))

	if threat > 0:
		var x = unit * (value - threat)
		var w = unit * threat
		var left_r = r if (value - threat) == 0 else 0
		var right_r = r if value == MaxValue else 0
		var box = makeBox(ThreatColor, left_r, right_r, left_r, right_r)
		box.draw(get_canvas_item(), Rect2(x, 0, w, size.y))

	for i in range(1, MaxValue):
		var px = unit * i
		var linePadding = size.y * 0.25
		if i % 5 == 0:
			draw_line(Vector2(px, 1.5), Vector2(px, size.y - 1.5), MediumTickColor, 1.0, true)
		else:
			draw_line(Vector2(px, linePadding), Vector2(px, size.y - linePadding), TickColor, 1.0, true)
