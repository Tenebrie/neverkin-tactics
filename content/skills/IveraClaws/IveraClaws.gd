extends Skill
class_name IveraClaws

const Damage = 1

func _ready() -> void:
	Definition = preload("res://content/skills/IveraClaws/IveraClaws.tres").duplicate()
	Definition.Telegraphs = [
		TelegraphPreset.MaxCastRange.new(),
		TelegraphPreset.SingleActor.new().WithDamageToHostiles(Damage)
	]
	super._ready()

func Cast(targets: Skill.TargetData) -> void:
	var actor = targets.actor
	var effect = IveraClawsStrikeEffect.new()
	get_parent().add_child(effect)
	effect.global_transform = Transform3D.IDENTITY
	effect.global_position = actor.global_position
	effect.position.y += 0.5
	effect.scale = Vector3(1.7,1.7,1.7)
	effect.Play()
	actor.stats.DealDamage(Damage)
