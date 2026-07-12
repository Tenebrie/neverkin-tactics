extends Skill
class_name SkillBreakFree

func _prepare() -> void:
	definition.telegraphs = [
		TelegraphPreset.SelfCast.new()
	]

func _cast(_targets: TargetData) -> void:
	parent.buffs.RemoveAll(SkillGriffonGripBuff)

func isVisible() -> bool:
	return parent.buffs.Has(SkillGriffonGripBuff)
