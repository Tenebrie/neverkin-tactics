extends Skill
class_name KamillaPistol

func _ready() -> void:
	Definition = preload("res://game/skills/KamillaPistol/KamillaPistol.tres")
	super._ready()

func Cast(targets: Skill.TargetData) -> void:
	var effect = KamillaPistolShotEffect.new()
	get_parent().add_child(effect)
	effect.global_position = Parent.global_position
	effect.position.y += 0.5

	var furthestPoint = (targets.mousePoint - Parent.global_position).normalized() * Definition.TargetingMaxRange
	effect.Play(furthestPoint)

	for actor in targets.actors:
		actor.stats.DealDamage(1)
