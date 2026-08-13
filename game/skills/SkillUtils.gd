class_name SkillUtils

enum MoveSpeed { Constant, Accelerating, Decelerating }

static func forceMoveTo(actor: Actor, destination: Vector3, speed: float = 10.0, speedPattern: MoveSpeed = MoveSpeed.Constant) -> void:
	const arcHeight = 2.0
	var start = actor.global_position
	var dist = ActorUtils.flatDistanceTo(actor, destination)
	var duration = dist / speed

	var collision = actor.collision_layer
	actor.collision_layer = 0

	var tween = actor.create_tween()
	match speedPattern:
		MoveSpeed.Constant:
			tween.set_trans(Tween.TRANS_LINEAR)
		MoveSpeed.Accelerating:
			tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		MoveSpeed.Decelerating:
			tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	tween.tween_method(
		func(t: float):
			var pos = start.lerp(destination, t)
			pos.y = start.y + sin(t * PI) * arcHeight
			actor.global_position = pos,
		0.0, 1.0, duration
	)

	await tween.finished
	actor.collision_layer = collision
	NavmeshManager.Instance.rebakeNavmeshForCurrentActor()
