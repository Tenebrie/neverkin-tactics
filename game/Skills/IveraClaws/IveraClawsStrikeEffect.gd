@tool
extends Node3D
class_name IveraClawsStrikeEffect

@export_tool_button("Play")
var hello_world := func() -> void:
	Play()

var duration: float = 0.3

func Play() -> void:
	createSwipeTrail(Vector3(-0.3, 0, -0.33), Vector3(0.2, 0, 0.2), 0.1)
	await get_tree().create_timer(0.01).timeout
	createSwipeTrail(Vector3(-0.25, 0, -0.36), Vector3(0.24, 0, 0.1), 0.08)
	await get_tree().create_timer(0.01).timeout
	createSwipeTrail(Vector3(-0.2, 0, -0.39), Vector3(0.28, 0, 0.0), 0.05)

func PlayInverted() -> void:
	createSwipeTrail(Vector3(-0.3, 0, -0.33), Vector3(0.2, 0, 0.2), -0.1)
	await get_tree().create_timer(0.01).timeout
	createSwipeTrail(Vector3(-0.25, 0, -0.36), Vector3(0.24, 0, 0.1), -0.08)
	await get_tree().create_timer(0.01).timeout
	createSwipeTrail(Vector3(-0.2, 0, -0.39), Vector3(0.28, 0, 0.0), -0.05)

func createSwipeTrail(from: Vector3, to: Vector3, arc: float) -> void:
	var trail := VaporTrail.new()
	trail.position = from
	trail.size = 0.05
	trail.emitting = true
	trail.num_points = 50
	trail.update_interval = 0.003
	trail.material = preload("res://addons/vaportrail/example/SmokyMaterial.tres")
	trail.size_curve = preload("res://game/Skills/IveraClaws/BasicClawsStrikeTrailCurve.tres")
	trail.time_curve = preload("res://game/Skills/IveraClaws/BasicClawsStrikeTrailTimeCurve.tres")
	trail.color_gradient = preload("res://game/Skills/IveraClaws/BasicClawsStrikeTrailGradient.tres")
	trail.time_color_gradient = preload("res://game/Skills/IveraClaws/BasicClawsStrikeTrailTimeGradient.tres")
	add_child(trail)

	var direction := (from - to).normalized()
	var sideways := Vector3(-direction.z, 0.0, direction.x)

	var tween := create_tween()
	tween.tween_method(func(t: float) -> void:
		var pos := from.lerp(to, t)
		pos -= sideways * arc * 4.0 * t * (1.0 - t)
		trail.position = pos
		trail.current_time = t
	, 0.0, 1.0, duration).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func() -> void:
		trail.emitting = false
	)

	await get_tree().create_timer(5.0).timeout
	trail.queue_free()
