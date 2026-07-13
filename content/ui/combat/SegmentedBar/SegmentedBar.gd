@tool
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

@export var CornerRadius = 6:
	set(v): CornerRadius = v; queue_redraw()

@export var BackgroundColor = Color(0.102, 0.102, 0.102, 0.302):
	set(v): BackgroundColor = v; queue_redraw()

@export var FillColor = Color.DARK_GREEN:
	set(v): FillColor = v; queue_redraw()

@export var InhumanColor = Color.DARK_MAGENTA:
	set(v): InhumanColor = v; queue_redraw()

@export var ThreatColor = Color.DARK_RED:
	set(v): ThreatColor = v; queue_redraw()

@export var TickColor = Color(0, 0, 0, 0.6):
	set(v): TickColor = v; queue_redraw()

@export var MediumTickColor = Color(0, 0, 0, 0.7):
	set(v): MediumTickColor = v; queue_redraw()

func _notification(what: int):
	if what == NOTIFICATION_RESIZED:
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

	var v = clampi(Value, 0, MaxValue)
	var threat = clampi(min(ThreatValue, v), 0, MaxValue)
	var inhuman = clampi(min(InhumanValue, v), 0, MaxValue)

	if v > 0:
		var right_r = r if v == MaxValue else 0
		var box = makeBox(FillColor, r, right_r, r, right_r)
		box.draw(get_canvas_item(), Rect2(0, 0, unit * v, size.y))

	if inhuman > 0:
		var right_r = r if inhuman == MaxValue else 0
		var box = makeBox(InhumanColor, r, right_r, r, right_r)
		box.draw(get_canvas_item(), Rect2(0, 0, unit * inhuman, size.y))

	if threat > 0:
		var x = unit * (v - threat)
		var w = unit * threat
		var left_r = r if (v - threat) == 0 else 0
		var right_r = r if v == MaxValue else 0
		var box = makeBox(ThreatColor, left_r, right_r, left_r, right_r)
		box.draw(get_canvas_item(), Rect2(x, 0, w, size.y))

	for i in range(1, MaxValue):
		var px = roundf(unit * i) + 0.5
		var linePadding = size.y * 0.25
		if i % 5 == 0:
			draw_line(Vector2(px, 1.5), Vector2(px, size.y - 1.5), MediumTickColor, 1.0, true)
		else:
			draw_line(Vector2(px, linePadding), Vector2(px, size.y - linePadding), TickColor, 1.0, true)
