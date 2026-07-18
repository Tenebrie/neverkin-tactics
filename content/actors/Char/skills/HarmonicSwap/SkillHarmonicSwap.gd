extends Skill
class_name SkillHarmonicSwap

const Damage = 2
const Healing = 1
const Cap = 5

var mainTelegraph: TelegraphDefinition = TelegraphPreset.CasterProjectile.new().WithWidth(0.04)
var secondaryTelegraph: TelegraphDefinition = TelegraphPreset.PointArea.new(0)

var firstTarget: Actor

func _prepare() -> void:
	definition.telegraphs = [
		mainTelegraph,
		secondaryTelegraph
	]

	secondaryTelegraph.Attachment = Telegraph.Attachment.None

	selected.connect(func():
		firstTarget = null
	)

	mainTelegraph.addTargetFilter(func(actor):
		return actor is not Prop
	)

	mainTelegraph.addValidator(func(telegraph):
		if telegraph.FilteredOnlyTargets.is_empty():
			return Error.new("No target")

		if telegraph.FilteredOnlyTargets[0] == firstTarget:
			return Error.new("Need a second target for swap")

		return true
	)

	mainTelegraph.HealthPromiseSelector = func(actor):
		var healingIfAlly = Healing if ActorUtils.isAlliedTo(parent, actor) else 0

		if not firstTarget:
			return healingIfAlly

		var diff = _getHealthDiff(actor, firstTarget)
		return diff

	mainTelegraph.HealthThreatSelector = func(actor):
		var damageIfEnemy = Damage if ActorUtils.isHostileTo(parent, actor) else 0

		if not firstTarget:
			return damageIfEnemy

		var diff = _getHealthDiff(actor, firstTarget)
		return -diff

	secondaryTelegraph.HealthPromiseSelector = func(actor):
		if actor != firstTarget:
			return 0

		var healingIfAlly = Healing if ActorUtils.isAlliedTo(parent, actor) else 0

		if mainTelegraph.getInstance().Targets.is_empty():
			return healingIfAlly

		var secondTarget = mainTelegraph.getInstance().Targets[0]
		var diff = _getHealthDiff(actor, secondTarget)
		return diff

	secondaryTelegraph.HealthThreatSelector = func(actor):
		if actor != firstTarget:
			return 0

		var damageIfEnemy = Damage if ActorUtils.isHostileTo(parent, actor) else 0

		if mainTelegraph.getInstance().Targets.is_empty():
			return damageIfEnemy

		var secondTarget = mainTelegraph.getInstance().Targets[0]
		var diff = _getHealthDiff(actor, secondTarget)
		return -diff

	secondaryTelegraph.addProcessor(func(telegraph):
		if firstTarget:
			telegraph.global_position = firstTarget.global_position
	)

func _getHealthDiff(mine: Actor, other: Actor) -> int:
	var healingIfAlly = Healing if ActorUtils.isAlliedTo(parent, mine) else 0
	var damageIfEnemy = Damage if ActorUtils.isHostileTo(parent, mine) else 0

	var firstDamage = mine.stats.healthDamageTaken
	var secondDamage = other.stats.healthDamageTaken

	var healthDiff = clampi(firstDamage - secondDamage, -Cap, Cap) + healingIfAlly - damageIfEnemy

	return healthDiff

func _cast(targets: TargetData) -> void:
	if parent.actions.recastsRemaining > 0:
		firstTarget = targets.actor
		return

	var def = ProjectileSystem.Definition.new()
	var effect = ProjectileSystem.Create(self)

	effect.theme.trailColorGradient = preload("./effect/SkillHarmonicSwapEffectGradientInitial.tres")
	def.arc = 0.2
	def.travelTime = 0.7
	def.tweenEaseType = Tween.EASE_IN
	effect.play(parent, firstTarget, def)
	effect.play(parent, targets.actor, def)

	await get_tree().create_timer(0.7).timeout

	for actor in targets.actors:
		actor.stats.applyDamageInstance(targets.damageInstances[actor])

	def.tweenEaseType = Tween.EASE_OUT

	if firstTarget.isAlive:
		effect.theme.trailColorGradient = preload("./effect/SkillHarmonicSwapEffectGradientHealing.tres") \
			if ActorUtils.isAlliedTo(parent, firstTarget) \
			else preload("./effect/SkillHarmonicSwapEffectGradientDamage.tres")
		effect.play(targets.actor, firstTarget, def)

	if targets.actor.isAlive:
		effect.theme.trailColorGradient = preload("./effect/SkillHarmonicSwapEffectGradientHealing.tres") \
			if ActorUtils.isAlliedTo(parent, targets.actor) \
			else preload("./effect/SkillHarmonicSwapEffectGradientDamage.tres")
		effect.play(firstTarget, targets.actor, def)

	firstTarget = null

func getRecastCount() -> int:
	return 1
