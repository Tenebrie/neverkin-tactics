extends Skill
class_name SkillKnifeSlash

const Damage = 2

func _ready() -> void:
	definition = preload("./SkillKnifeSlashDefinition.tres").duplicate()
	definition.telegraphs = [
		TelegraphPreset.MaxCastRange.new(),
		TelegraphPreset.SingleActor.new().WithDamageToHostiles(Damage)
	]
	super._ready()

func _cast(targets: Skill.TargetData) -> void:
	var actor = targets.actor
	var effect = SkillKnifeSlashEffect.new()
	get_tree().current_scene.add_child(effect)
	effect.global_position = actor.global_position
	effect.global_position.y = 2
	effect.Play()
	get_tree().create_timer(0.1).timeout.connect(func():
		actor.stats.dealSkillDamage(targets)
	)
