extends Skill
class_name SkillGriffonGrip

var targetTelegraph = TelegraphPreset.SingleActor.new()

func _prepare() -> void:
	targetTelegraph.addTargetFilter(func(actor):
		return actor is not Prop
	)
	definition.telegraphs = [
		TelegraphPreset.MaxCastRange.new(),
		targetTelegraph
	]

func _cast(targets: Skill.TargetData) -> void:
	if targets.actor.Buffs.Has(SkillGriffonGripBuff):
		targets.actor.Buffs.RemoveAll(SkillGriffonGripBuff)
	else:
		var buff = SkillGriffonGripBuff.new()
		targets.actor.Buffs.Add(buff)
