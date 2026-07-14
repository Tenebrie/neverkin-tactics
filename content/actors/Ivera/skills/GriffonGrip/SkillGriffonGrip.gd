extends Skill
class_name SkillGriffonGrip

var targetTelegraph = TelegraphPreset.SingleActor.new()

func _prepare() -> void:
	targetTelegraph.addTargetFilter(func(actor):
		return actor is not Prop and actor != parent
	)
	definition.telegraphs = [
		TelegraphPreset.MaxCastRange.new(),
		targetTelegraph
	]

func _cast(targets: Skill.TargetData) -> void:
	if targets.actor.buffs.Has(SkillGriffonGripBuff):
		targets.actor.buffs.RemoveAll(SkillGriffonGripBuff)
	else:
		var buff = SkillGriffonGripBuff.new()
		targets.actor.buffs.Add(buff)
