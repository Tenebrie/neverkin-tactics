@tool
extends Node3D
class_name SkillPistolShotEffect

func Play(target: Vector3, duration: float = 0.2) -> void:
	createSwipeTrail(Vector3.ZERO, target, 0, duration)

func createSwipeTrail(from: Vector3, to: Vector3, arc: float, duration: float) -> void:
	var trail := VaporTrail.new()
	trail.position = from
	trail.size = 0.05
	trail.emitting = true
	trail.num_points = 50
	trail.update_interval = 0.014
	trail.material = preload("res://addons/vaportrail/example/SmokyMaterial.tres")
	trail.size_curve = preload("res://content/effects/KineticWeaponTrail/KineticWeaponTrailCurve.tres")
	trail.time_curve = preload("res://content/effects/KineticWeaponTrail/KineticWeaponTrailTimeCurve.tres")
	trail.color_gradient = preload("res://content/effects/KineticWeaponTrail/KineticWeaponTrailGradient.tres")
	trail.time_color_gradient = preload("res://content/effects/KineticWeaponTrail/KineticWeaponTrailTimeGradient.tres")
	add_child(trail)

	var direction := (from - to).normalized()
	var sideways := Vector3(-direction.z, 0.0, direction.x)

	var tween := create_tween()
	tween.tween_method(func(t: float) -> void:
		var pos := from.lerp(to, t)
		pos -= sideways * arc * 4.0 * t * (1.0 - t)
		trail.position = pos
		trail.current_time = t
	, 0.0, 1.0, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)

	tween.tween_callback(func() -> void:
		trail.emitting = false
	)

	await get_tree().create_timer(5.0).timeout
	trail.queue_free()
