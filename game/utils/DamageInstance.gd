class_name DamageInstance

var Value: int = 0
var SourceActor: Actor
var SourceSkill: Skill

var GrudgeString: String

func _to_string() -> String:
	return "<DamageInstance Value=%d SourceActor=%s SourceSkill=%s>"%[Value, SourceActor, SourceSkill]

static func ForSkillCast(target: Actor, targetData: Skill.TargetData) -> DamageInstance:
	var instance = DamageInstance.new()
	instance.SourceSkill = targetData.SourceSkill
	instance.SourceActor = targetData.SourceSkill.Parent

	for def in targetData.SourceSkill.Definition.Telegraphs:
		var telegraphTargets = targetData.PerTelegraph[def]
		if not telegraphTargets.has(target):
			continue
		instance.Value += def.HealthThreatSelector.call(target)
	return instance
