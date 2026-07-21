extends Skill
class_name SkillGriffonSmash

const Damage = 2
const GrabbedVictimDamage = 1
const GrabbedVictimWallsPerDamage = 5

const GrabbedVictimDamagePerWall = float(GrabbedVictimDamage) / GrabbedVictimWallsPerDamage

var mainTelegraph = TelegraphPreset.PointArea.new(0.0)

func _prepare() -> void:
	mainTelegraph.fillFraction = 0.0
	mainTelegraph.CircleRadius = definition.TargetingMaxRange + parent.physicalSize

	mainTelegraph.collideWithObstacles()
	mainTelegraph.Attachment = Telegraph.Attachment.Caster
	mainTelegraph.addTargetFilter(func(actor):
		return actor != parent
	)
	mainTelegraph.HealthThreatSelector = func(actor):
		var grabbedTarget = _findGrabbedTarget()
		if actor == grabbedTarget:
			var agentCount = -1
			var wallCount = 0
			for target in mainTelegraph.getInstance().Targets:
				if target is Prop:
					wallCount += 1
				else:
					agentCount += 1
			return agentCount * GrabbedVictimDamage + floori(wallCount * GrabbedVictimDamagePerWall)
		return Damage

	definition.telegraphs = [
		mainTelegraph
	]

func _findGrabbedTarget() -> Actor:
	for actorWithBuff in parent.query.allLivingAgents.inRange(2.0).withBuff(SkillGriffonGripBuff).collect():
		return actorWithBuff
	return null

func _cast(targets: TargetData) -> void:
	var tween = create_tween().set_parallel()
	tween.tween_property(parent, "rotation:y", rotation.y + TAU, 0.75).as_relative()

	var victim = _findGrabbedTarget()
	if victim:
		var offset = victim.global_position - parent.global_position
		# Godot Y-rotation convention: angle measured so it matches rotation.y
		var start_angle = atan2(offset.x, offset.z)
		var rotationRadius = Vector2(offset.x, offset.z).length()
		var start_facing = victim.rotation.y
		tween.tween_method(
			func(angle: float):
				var pos = Vector3(sin(angle), 0.0, cos(angle)) * rotationRadius
				victim.global_position = parent.global_position + pos
				victim.rotation.y = start_facing + (angle - start_angle),
			start_angle, start_angle + TAU, 0.75
		)

	for target in targets.actors:
		target.stats.dealSkillDamage(targets)
