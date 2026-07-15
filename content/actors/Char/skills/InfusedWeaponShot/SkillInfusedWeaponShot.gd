extends Skill
class_name SkillInfusedWeaponShot

var Damage = 2
var Healing = 2
var HitboxWidth = 0.04

var damageTelegraph: TelegraphDefinition = TelegraphPreset.Projectile.new().TargetingHostiles().WithDamage(Damage).WithWidth(HitboxWidth)
var healingTelegraph: TelegraphDefinition = TelegraphPreset.Projectile.new().TargetingAllies().WithHealing(Healing).WithWidth(HitboxWidth)

func _prepare() -> void:
	definition.keywords = [Keyword.Reloadable]
	definition.telegraphs = [
		damageTelegraph
	]
	healingTelegraph.addTargetFilter(func(actor):
		return actor != parent
	)

	preparingInfuseChanged.connect(func():
		if preparingInfuse:
			definition.ManaCost = 1
			definition.telegraphs = [healingTelegraph]
		else:
			definition.ManaCost = 0
			definition.telegraphs = [damageTelegraph]
	)

func isInfusable() -> bool:
	return parent.stats.manaCurrent >= 1

func _cast(allTargets: Skill.TargetData) -> void:
	var effect = SkillInfusedWeaponShotEffect.new()
	get_parent().add_child(effect)
	effect.global_position = parent.global_position
	effect.position.y += 0.5
	effect.infused = allTargets.infusedCast

	var targets: Array[Actor]
	if allTargets.perTelegraph.has(damageTelegraph):
		targets = allTargets.perTelegraph[damageTelegraph]
	elif allTargets.perTelegraph.has(healingTelegraph):
		targets = allTargets.perTelegraph[healingTelegraph]

	if targets.size() == 0:
		var furthestPoint = (allTargets.mousePoint - parent.global_position).normalized() * definition.TargetingMaxRange
		effect.Play(furthestPoint)

	var furthest: Actor = null
	for actor in targets:
		actor.stats.dealSkillDamage(allTargets)
		if not furthest or furthest.global_position.distance_squared_to(parent.global_position) < actor.global_position.distance_squared_to(parent.global_position):
			furthest = actor
	if furthest:
		var distance = furthest.global_position.distance_to(parent.global_position)
		var furthestPoint = (allTargets.mousePoint - parent.global_position).normalized() * distance
		var effectDuration = furthestPoint.length() / distance
		effect.Play(furthestPoint, 0.2 * effectDuration)
