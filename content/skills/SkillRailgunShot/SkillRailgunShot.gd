extends Skill
class_name SkillRailgunShot

var Damage = 5
var HitboxWidth = 0.1

var damageTelegraph = TelegraphPreset.CasterProjectile.new().TargetingHostiles().WithDamage(Damage).WithWidth(HitboxWidth)

func _ready() -> void:
	definition = preload("res://content/skills/SkillRailgunShot/SkillRailgunShot.tres").duplicate()
	damageTelegraph.PenetrationPower = 9
	damageTelegraph.PiercingPower = 2
	definition.telegraphs = [
		damageTelegraph
	]
	super._ready()

func _cast(targets: Skill.TargetData) -> void:
	var effect = SkillRailgunShotEffect.new()
	get_parent().add_child(effect)
	effect.global_position = parent.global_position
	effect.position.y += 0.5

	var furthestPoint = (targets.mousePoint - parent.global_position).normalized() * definition.TargetingMaxRange
	effect.Play(furthestPoint)

	for actor in targets.perTelegraph[damageTelegraph]:
		actor.stats.dealSkillDamage(targets)
