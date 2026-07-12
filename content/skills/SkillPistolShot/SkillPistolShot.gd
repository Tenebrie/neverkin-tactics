extends Skill
class_name SkillPistolShot

var Damage = 2
var HitboxWidth = 0.04

var damageTelegraph: TelegraphDefinition = TelegraphPreset.StandardProjectile.new().WithDamage(Damage).WithWidth(HitboxWidth)

func _ready() -> void:
	definition = preload("res://content/skills/SkillPistolShot/SkillPistolShot.tres").duplicate()

	definition.telegraphs = [
		damageTelegraph
	]
	super._ready()

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
		actor.Stats.DealSkillDamage(targets)
		if not furthest or furthest.global_position.distance_squared_to(parent.global_position) < actor.global_position.distance_squared_to(parent.global_position):
			furthest = actor
	if furthest:
		var distance = furthest.global_position.distance_to(parent.global_position)
		var furthestPoint = (targets.mousePoint - parent.global_position).normalized() * distance
		var effectDuration = furthestPoint.length() / distance
		effect.Play(furthestPoint, 0.2 * effectDuration)
