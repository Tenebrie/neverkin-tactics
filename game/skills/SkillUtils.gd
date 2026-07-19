class_name SkillUtils

static func forceMoveTo(actor: Actor, point: Vector3, speed: float = 10.0) -> void:
	var dist = ActorUtils.flatDistanceTo(actor, point)
	var duration = dist / speed

	actor.create_tween().tween_property(actor, "global_position", point, duration)
	var collision = actor.collision_layer
	actor.collision_layer = 0
	await actor.get_tree().create_timer(duration).timeout
	actor.collision_layer = collision
