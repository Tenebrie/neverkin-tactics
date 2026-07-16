extends Skill
class_name SkillSoulweave

const Damage = 1
const Healing = 1
const HitboxWidth = 0.06

var mainTelegraph: TelegraphDefinition = TelegraphPreset.Projectile.new().WithWidth(HitboxWidth)

func _prepare() -> void:
	definition.telegraphs = [
		mainTelegraph
	]
	mainTelegraph.PiercingPower = 100
	mainTelegraph.PenetrationPower = 100
	mainTelegraph.addTargetFilter(func(actor):
		return actor != parent and actor is not Prop
	)
	mainTelegraph.HealthThreatSelector = func(actor):
		return Damage if not ActorUtils.isAlliedTo(actor, parent) else 0
	mainTelegraph.HealthPromiseSelector = func(actor):
		return Healing if ActorUtils.isAlliedTo(actor, parent) else 0

func _cast(targets: Skill.TargetData) -> void:
	var effect = ProjectileSystem.Create(self)
	var projectile = ProjectileSystem.Definition.new()
	projectile.width = HitboxWidth

	var furthestPoint = (targets.mousePoint - parent.global_position).normalized() * definition.TargetingMaxRange
	effect.play(parent, parent.global_position + furthestPoint, projectile)

	for target in targets.perTelegraph[mainTelegraph]:
		target.buffs.Add(BuffSoulbind.new())
		target.stats.dealSkillDamage(targets)
