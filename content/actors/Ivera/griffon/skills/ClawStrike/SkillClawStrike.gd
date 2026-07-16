extends Skill
class_name SkillClawStrike

const Damage = 1
const MaxBleedStacks = 3
const MaxShiftedBleedStacks = 5

var currentMaxBleedStacks:
	get:
		if parent.isShapeshifted:
			return MaxShiftedBleedStacks
		return MaxBleedStacks

func _prepare() -> void:
	definition.telegraphs = [
		TelegraphPreset.MaxCastRange.new(),
		TelegraphPreset.SingleActor.new().WithDamageToHostiles(Damage)
	]

func _cast(targets: Skill.TargetData) -> void:
	var actor = targets.actor
	var effect = SkillClawStrikeEffect.new()
	get_tree().current_scene.add_child(effect)
	effect.global_position = actor.global_position
	effect.global_position.y = 2
	effect.Play()
	get_tree().create_timer(0.1).timeout.connect(func():
		actor.stats.dealSkillDamage(targets)
		var maxStacks = MaxShiftedBleedStacks if parent.isShapeshifted else MaxBleedStacks
		actor.buffs.AddUpToMaxIntensity(BuffBleeding.Build(self), maxStacks)
	)
