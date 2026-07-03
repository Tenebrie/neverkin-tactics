extends Skill
class_name KamillaPistol

var Damage = 1
var HitboxWidth = 0.04

var damageTelegraph = TelegraphPreset.Projectile.new().TargetingHostiles().WithDamage(Damage).WithWidth(HitboxWidth)

func _ready() -> void:
	Definition = preload("res://game/skills/KamillaPistol/KamillaPistol.tres").duplicate()

	Definition.Telegraphs = [
		damageTelegraph
	]
	super._ready()

func Cast(targets: Skill.TargetData) -> void:
	var effect = KamillaPistolShotEffect.new()
	get_parent().add_child(effect)
	effect.global_position = Parent.global_position
	effect.position.y += 0.5

	if targets.perTelegraph[damageTelegraph].size() == 0:
		var furthestPoint = (targets.mousePoint - Parent.global_position).normalized() * Definition.TargetingMaxRange
		effect.Play(furthestPoint)

	for actor in targets.perTelegraph[damageTelegraph]:
		actor.stats.DealDamage(Damage)
		var effectVector = actor.global_position - Parent.global_position
		var effectDuration = effectVector.length() / Definition.TargetingMaxRange
		effect.Play(effectVector, 0.2 * effectDuration)
