extends Skill
class_name SkillPistolShot

var Damage = 1
var HitboxWidth = 0.04

var damageTelegraph: TelegraphDefinition = TelegraphPreset.StandardProjectile.new().WithDamage(Damage).WithWidth(HitboxWidth)

func _ready() -> void:
	Definition = preload("res://content/skills/SkillPistolShot/SkillPistolShot.tres").duplicate()

	Definition.Telegraphs = [
		damageTelegraph
	]
	super._ready()

func Cast(targets: Skill.TargetData) -> void:
	var effect = SkillPistolShotEffect.new()
	get_parent().add_child(effect)
	effect.global_position = Parent.global_position
	effect.position.y += 0.5

	if targets.perTelegraph[damageTelegraph].size() == 0:
		var furthestPoint = (targets.mousePoint - Parent.global_position).normalized() * Definition.TargetingMaxRange
		effect.Play(furthestPoint)

	var furthest: Actor = null
	for actor in targets.perTelegraph[damageTelegraph]:
		actor.Stats.DealDamage(Damage, Parent)
		if not furthest or furthest.global_position.distance_squared_to(Parent.global_position) < actor.global_position.distance_squared_to(Parent.global_position):
			furthest = actor
	if furthest:
		var distance = furthest.global_position.distance_to(Parent.global_position)
		var furthestPoint = (targets.mousePoint - Parent.global_position).normalized() * distance
		var effectDuration = furthestPoint.length() / distance
		effect.Play(furthestPoint, 0.2 * effectDuration)
