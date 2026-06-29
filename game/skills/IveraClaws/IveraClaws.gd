extends Skill
class_name IveraClaws

func _ready() -> void:
	Definition = preload("res://game/skills/IveraClaws/IveraClaws.tres")
	super._ready()

func Cast(targets: Skill.TargetData) -> void:
	var actor = targets.actor
	var effect = IveraClawsStrikeEffect.new()
	get_parent().add_child(effect)
	effect.global_transform = Transform3D.IDENTITY
	effect.global_position = actor.global_position
	effect.position.y += 0.5
	effect.Play()
	actor.stats.DealDamage(GetHealthDamage(actor))
