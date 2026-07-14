extends Skill
class_name SkillChromaShot

var damagePerShot = 1
var shotCount = 3
var hitboxWidth = 0.04

var damageTelegraph: TelegraphDefinition = TelegraphPreset.StandardProjectile.new().WithDamage(damagePerShot).WithWidth(hitboxWidth)
var shotsRemainingTelegraph: TelegraphDefinition = TelegraphPreset.MouseText.new("")

func _prepare() -> void:
	definition.telegraphs = [
		damageTelegraph,
		shotsRemainingTelegraph
	]

	selected.connect(func():
		shotsRemainingTelegraph.TextMessage = ""
	)

	afterCast.connect(func():
		if parent.actions.recastsRemaining > 0:
			shotsRemainingTelegraph.TextMessage = "Shots: %d/%d"%[parent.actions.recastsRemaining, shotCount]
		else:
			shotsRemainingTelegraph.TextMessage = ""
	)

	parent.turnEnded.connect(func():
		chargesUsed = 0
	)

func getRecastCount() -> int:
	return shotCount - 1

func _cast(targets: Skill.TargetData) -> void:
	var effect = SkillPistolShotEffect.new()
	get_parent().add_child(effect)
	effect.global_position = parent.global_position
	effect.position.y += 0.5

	if targets.perTelegraph[damageTelegraph].size() == 0:
		var furthestPoint = (targets.mousePoint - parent.global_position).normalized() * definition.TargetingMaxRange
		effect.Play(furthestPoint)

	var furthest: Actor = null
	for actor in targets.perTelegraph[damageTelegraph]:
		actor.stats.dealSkillDamage(targets)
		if not furthest or furthest.global_position.distance_squared_to(parent.global_position) < actor.global_position.distance_squared_to(parent.global_position):
			furthest = actor
	if furthest:
		var distance = furthest.global_position.distance_to(parent.global_position)
		var furthestPoint = (targets.mousePoint - parent.global_position).normalized() * distance
		var effectDuration = furthestPoint.length() / distance
		effect.Play(furthestPoint, 0.2 * effectDuration)
