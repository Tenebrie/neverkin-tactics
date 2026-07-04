extends Skill
class_name SkillRailgunShot

var Damage = 3
var HitboxWidth = 0.1

var damageTelegraph = TelegraphPreset.Projectile.new().TargetingHostiles().WithDamage(Damage).WithWidth(HitboxWidth)

func _ready() -> void:
	Definition = preload("res://content/skills/SkillRailgunShot/SkillRailgunShot.tres").duplicate()
	damageTelegraph.PenetrationPower = 1
	damageTelegraph.PiercingPower = 1
	Definition.Telegraphs = [
		damageTelegraph
	]
	super._ready()

func Cast(targets: Skill.TargetData) -> void:
	var effect = SkillRailgunShotEffect.new()
	get_parent().add_child(effect)
	effect.global_position = Parent.global_position
	effect.position.y += 0.5

	var furthestPoint = (targets.mousePoint - Parent.global_position).normalized() * Definition.TargetingMaxRange
	effect.Play(furthestPoint)

	for actor in targets.perTelegraph[damageTelegraph]:
		actor.Stats.DealDamage(Damage, Parent)
