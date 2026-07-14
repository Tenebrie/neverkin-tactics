extends Skill
class_name SkillReload

func _prepare() -> void:
	definition.telegraphs = [
		TelegraphPreset.SelfCast.new()
	]

func isCastable() -> Variant:
	var reloadableSkill = parent.Skills.GetByKeyword(Keyword.Reloadable)
	if not reloadableSkill or reloadableSkill.chargesUsed == 0:
		return Error.new("Magazine full")
	return super.isCastable()

func isVisible() -> bool:
	var reloadableSkill = parent.Skills.GetByKeyword(Keyword.Reloadable)
	if not reloadableSkill:
		return false
	return super.isVisible()

func _cast(_t) -> void:
	var reloadableSkill = parent.Skills.GetByKeyword(Keyword.Reloadable)
	reloadableSkill.restoreCharges(1000)
