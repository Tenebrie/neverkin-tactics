class_name DamageInstance

var Value: int = 0
var sourceActor: Actor
var sourceSkill: Skill

var GrudgeString: String

func _to_string() -> String:
	return "<DamageInstance Value=%d sourceActor=%s sourceSkill=%s>"%[Value, sourceActor, sourceSkill]

static func ForDelayedTelegraph(target: Actor, sourceSkill: Skill, telegraph: Telegraph) -> DamageInstance:
	var instance = DamageInstance.new()
	instance.sourceSkill = sourceSkill
	instance.sourceActor = sourceSkill.parent
	instance.Value = telegraph.definition.HealthThreatSelector.call(target)
	return instance

static func ForSkillCast(target: Actor, targetData: Skill.TargetData) -> DamageInstance:
	var instance = DamageInstance.new()
	instance.sourceSkill = targetData.sourceSkill
	instance.sourceActor = targetData.sourceSkill.parent

	for def in targetData.sourceSkill.definition.telegraphs:
		var telegraphTargets = targetData.perTelegraph[def]
		if not telegraphTargets.has(target):
			continue
		instance.Value += def.HealthThreatSelector.call(target)
	return instance

static func ForAggroGeneration(sourceSkill: Skill, value: int) -> DamageInstance:
	var instance = DamageInstance.new()
	instance.sourceSkill = sourceSkill
	instance.sourceActor = sourceSkill.parent
	instance.Value = value
	return instance

static func ForSkill(sourceSkill: Skill, value: int) -> DamageInstance:
	var instance = DamageInstance.new()
	instance.sourceSkill = sourceSkill
	instance.sourceActor = sourceSkill.parent
	instance.Value = value
	return instance
