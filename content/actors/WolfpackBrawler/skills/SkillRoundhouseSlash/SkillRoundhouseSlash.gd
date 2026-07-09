extends Skill
class_name SkillRoundhouseSlash

const Damage = 1
const AttackArea = 1.2

var damageArea = TelegraphPreset.PointArea.new(AttackArea).WithDamageToHostiles(Damage)

func _ready() -> void:
	Definition = preload("./SkillRoundhouseSlash.tres").duplicate()
	damageArea.Attachment = Telegraph.Attachment.Caster
	Definition.Telegraphs = [
		damageArea
	]
	super._ready()

func Cast(targets: Skill.TargetData) -> void:
	for target in targets.PerTelegraph[damageArea]:
		var effect = SkillKnifeSlashEffect.new()
		get_tree().current_scene.add_child(effect)
		effect.global_position = target.global_position
		effect.global_position.y = 2
		effect.Play()
		get_tree().create_timer(0.1).timeout.connect(func():
			target.Stats.DealSkillDamage(targets)
		)
