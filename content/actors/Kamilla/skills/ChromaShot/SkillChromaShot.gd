extends Skill
class_name SkillChromaShot

const NormalShotCount = 2
const ChargedShotCount = 7

var damagePerShot = 1
var shotCount: int:
	get:
		if definition and getChromaComponent().chargeCount >= definition.ChargesMaximum:
			return ChargedShotCount
		return NormalShotCount

var hitboxWidth = 0.04
var chargesGenerated = 1

var damageTelegraphs: Array[TelegraphDefinition]

func _prepare() -> void:
	for shotIndex in ChargedShotCount:
		var newTelegraph: TelegraphDefinition = TelegraphPreset.CasterProjectile.new()
			.TargetingHostiles()
			.WithDamage(damagePerShot)
			.WithWidth(hitboxWidth)

		newTelegraph.addTargetFilter(func(actor):
			if shotIndex >= shotCount:
				return false

			var actorVirtualHealth = actor.stats.healthCurrent
			for i in shotIndex:
				if damageTelegraphs[i].getInstance().FirstTarget == actor:
					actorVirtualHealth -= damagePerShot
			return actorVirtualHealth > 0
		)
		newTelegraph.addPostProcessor(func(telegraph):
			if shotIndex >= shotCount:
				telegraph.Tint = Color.TRANSPARENT
		)
		damageTelegraphs.push_back(newTelegraph)

	definition.telegraphs = damageTelegraphs
	definition.keywords = [Keyword.Chroma]
	chargesLeft = 0

func _cast(targets: Skill.TargetData) -> void:
	var effect = SkillPistolShotEffect.new()
	get_parent().add_child(effect)
	effect.global_position = parent.global_position
	effect.position.y += 0.5

	for i in shotCount:
		if targets.perTelegraph[damageTelegraphs[i]].size() == 0:
			var furthestPoint = (targets.mousePoint - parent.global_position).normalized() * definition.TargetingMaxRange
			effect.Play(furthestPoint)

		var furthest: Actor = null

		for actor in targets.perTelegraph[damageTelegraphs[i]]:
			actor.stats.dealSkillTelegraphDamage(targets, damageTelegraphs[i])
			if not furthest or furthest.global_position.distance_squared_to(parent.global_position) < actor.global_position.distance_squared_to(parent.global_position):
				furthest = actor

		if furthest:
			var distance = furthest.global_position.distance_to(parent.global_position)
			var furthestPoint = (targets.mousePoint - parent.global_position).normalized() * distance
			var effectDuration = furthestPoint.length() / distance
			effect.Play(furthestPoint, 0.2 * effectDuration)

		if shotCount == NormalShotCount:
			await get_tree().create_timer(0.15).timeout
		else:
			await get_tree().create_timer(0.06).timeout

func getChromaComponent() -> ChromaComponent:
	return parent.GetComponent(ChromaComponent)
