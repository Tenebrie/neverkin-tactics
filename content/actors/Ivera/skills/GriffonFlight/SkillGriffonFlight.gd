extends Skill
class_name SkillGriffonFlight

var landingDamage = 1

var casterTelegraph = TelegraphPreset.PointArea.new(0.1)

func _prepare() -> void:
	casterTelegraph.CircleRadius = parent.physicalSize
	casterTelegraph.Validators.push_back(func(telegraph: Telegraph):
		if not telegraph.IsPathable(parent.physicalSize):
			return Error.new("Not enough free space at destination.")
	)

	casterTelegraph.Processors = []
	casterTelegraph.Processors.push_back(func(telegraph: Telegraph):
		if telegraph.IsPathable(parent.physicalSize):
			telegraph.Tint = TelegraphColor.ExclusionGood
		else:
			telegraph.Tint = TelegraphColor.ExclusionOccupied
	)
	casterTelegraph.Processors.push_back(TelegraphProcessor.OutOfRangeTint)

	definition.telegraphs = [
		casterTelegraph,
		TelegraphPreset.MaxCastRange.new()
	]

func _cast(targets: TargetData) -> void:
	var collision = parent.collision_layer
	parent.collision_layer = 0
	var direction = (targets.mousePoint - parent.global_position).normalized()
	var springDist = 0.2
	var startPos = parent.global_position - direction * springDist + Vector3(0, 0, 0.2)
	var endPos = targets.mousePoint
	var arcHeight = startPos.distance_to(endPos) / 4.0
	var duration = 0.85

	var grabTimer: Timer
	var grabbedActors = Actor.Repository.Alive.List.filter(func(a):
		return a.Buffs and a.Buffs.Has(SkillGriffonGripBuff)
	)
	if grabbedActors.size() > 0:
		var grabTarget = grabbedActors[0]
		var grabOffset = grabTarget.global_position - parent.global_position
		grabTimer = Timer.new()
		add_child(grabTimer)
		grabTimer.wait_time = 0.005
		grabTimer.timeout.connect(func():
			grabTarget.global_position = parent.global_position + grabOffset
		)
		grabTimer.start()

	var tween = create_tween()

	tween.tween_property(parent, "global_position", startPos, 0.4) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(
		func(t: float) -> void:
			var pos = (startPos).lerp(endPos, t)
			#var hop = pow(sin(t * PI), 2.5)
			#if t >= 0.5:
				#hop = 1.0 / t - 1.0
			var hop = ((t * 2.0 - 1.0) ** 2)
			#pos.y += hop * 1.0
			#pos.z -= hop * arcHeight * 2.00
			#pos.z += pow(t, 3.0) * 0.15
			pos.z += (hop - 1.0) * arcHeight
			parent.global_position = pos,
		0.0, 1.0, duration
	).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	tween.tween_callback(func():
		if grabTimer and ActorUtils.isHostileTo(parent, grabbedActors[0]):
			grabbedActors[0].Stats.DealDamage(DamageInstance.ForExtraSkillEffect(self, landingDamage))
	)

	var landZ = targets.mousePoint.z
	#tween.tween_property(parent, "global_position:z", landZ, duration * 0.5)
		#.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished
	if grabTimer:
		grabTimer.queue_free()

	parent.collision_layer = collision
