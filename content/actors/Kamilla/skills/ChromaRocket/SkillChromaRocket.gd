extends Skill
class_name SkillChromaRocket

const NormalDamage = 2
const ChargedAoeDamage = 2
const ChargedAoeRadius = 1.0

const NormalMetersPushed = 2.5
const ChargedMetersPushed = 20.0

var damagePerShot: int:
	get:
		return NormalDamage
var metersPushed: float:
	get:
		if definition and chargesLeft >= definition.ChargesMaximum:
			return ChargedMetersPushed
		else:
			return NormalMetersPushed

var hitboxWidth = 0.08
var chargesGenerated = 1

var damageTelegraph: TelegraphDefinition = TelegraphPreset.CasterProjectile.new()
	.TargetingHostiles()
	.WithWidth(hitboxWidth)
var explosionTelegraph: TelegraphDefinition = TelegraphPreset.ExplosionArea.new(ChargedAoeRadius)

var pushTelegraph = TelegraphPreset.ForcePush.new(1.0)

func _prepare() -> void:
	definition.telegraphs = [
		damageTelegraph,
		explosionTelegraph,
		pushTelegraph.Travel,
		pushTelegraph.Impact,
	]
	definition.keywords = [Keyword.Chroma]
	chargesLeft = 0

	damageTelegraph.HealthThreatSelector = func():
		const BonkDamage = 1
		return damagePerShot + (BonkDamage if pushTelegraph.Impact.getInstance().Targets.size() > 0 else 0)

	explosionTelegraph.HealthThreat = ChargedAoeDamage
	explosionTelegraph.addProcessor(func(telegraph):
		if chargesLeft < definition.ChargesMaximum or not damageTelegraph.getInstance().FirstTarget:
			return
		telegraph.global_position = damageTelegraph.getInstance().FirstTarget.global_position
		telegraph.global_position.y -= 0.01
	)
	explosionTelegraph.addTargetFilter(func():
		var isCharged = chargesLeft >= definition.ChargesMaximum
		return isCharged and damageTelegraph.getInstance().FirstTarget != null
	)

	pushTelegraph.setTargetFromSelector(func():
		var target = damageTelegraph.getInstance().FirstTarget
		if target is Prop:
			return null
		return target
	)
	pushTelegraph.setWidthFromSelector(func():
		var target = damageTelegraph.getInstance().FirstTarget
		if not target:
			return 1.0
		return target.physicalSize * 2.0
	)
	pushTelegraph.setDirectionPushFromCaster()
	pushTelegraph.setDistanceFromSelector(func(): return metersPushed)
	pushTelegraph.setHiddenWithoutTarget()

func _cast(targets: Skill.TargetData) -> void:
	var system = ProjectileSystem.Create(self)
	system.theme.trailSizeCurve = preload("res://content/effects/KineticWeaponTrail/KineticWeaponTrailCurve.tres")
	system.theme.trailColorGradient = preload("res://content/effects/KineticWeaponTrail/KineticWeaponTrailGradient.tres")
	system.theme.trailTimeSizeCurve = preload("res://content/effects/KineticWeaponTrail/KineticWeaponTrailTimeCurve.tres")
	system.theme.trailTimeColorGradient = preload("res://content/effects/KineticWeaponTrail/KineticWeaponTrailTimeGradient.tres")

	if targets.perTelegraph[damageTelegraph].size() == 0:
		var furthestPoint = (targets.mousePoint - parent.global_position).normalized() * definition.TargetingMaxRange
		system.play(ActorUtils.flatPositionOf(parent), furthestPoint + ActorUtils.flatPositionOf(parent))
		return

	var victim: Actor = targets.perTelegraph[damageTelegraph][0]

	var distance = victim.global_position.distance_to(parent.global_position)
	var effectDef = ProjectileSystem.Definition.new()
	effectDef.travelTime = distance * 0.05
	system.play(ActorUtils.flatPositionOf(parent), ActorUtils.flatPositionOf(victim), effectDef)

	await get_tree().create_timer(effectDef.travelTime).timeout

	if targets.perTelegraph[explosionTelegraph].size() > 0:
		for explosionVictim in targets.perTelegraph[explosionTelegraph]:
			explosionVictim.stats.dealSkillDamage(targets)
	else:
		victim.stats.dealSkillDamage(targets)

	if victim is not Prop:
		await SkillUtils.forceMoveTo(victim, targets.endpointPerTelegraph[pushTelegraph.Travel])

	for actor in targets.perTelegraph[pushTelegraph.Impact]:
		actor.stats.dealSkillDamage(targets)

func getChromaComponent() -> ChromaComponent:
	return parent.GetComponent(ChromaComponent)
