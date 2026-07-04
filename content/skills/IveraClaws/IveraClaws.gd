extends Skill
class_name IveraClaws

const Damage = 1

func _ready() -> void:
	Definition = preload("./IveraClaws.tres").duplicate()
	Definition.Telegraphs = [
		TelegraphPreset.MaxCastRange.new(),
		TelegraphPreset.SingleActor.new().WithDamageToHostiles(Damage)
	]
	super._ready()

func Cast(targets: Skill.TargetData) -> void:
	var actor = targets.actor
	var effect = IveraClawsStrikeEffect.new()
	get_tree().current_scene.add_child(effect)
	effect.global_position = actor.global_position
	effect.global_position.y = 2
	effect.scale = Vector3(1.7,1.7,1.7)
	effect.Play()
	get_tree().create_timer(0.1).timeout.connect(func():
		actor.Stats.DealDamage(Damage)
	)
