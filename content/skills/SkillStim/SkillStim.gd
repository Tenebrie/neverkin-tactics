extends Skill
class_name SkillStim

func _prepare() -> void:
	definition.telegraphs = [
		TelegraphPreset.SelfCast.new()
	]

func _cast(_targets: Skill.TargetData) -> void:
	var stim = BuffStim.new()
	stim.Duration = 2
	parent.buffs.Add(stim)
