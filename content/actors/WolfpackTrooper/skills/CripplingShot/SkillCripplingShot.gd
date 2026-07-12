extends SkillPistolShot
class_name SkillCripplingShot

func _prepare() -> void:
	super._prepare()
	var newDefinition = preload("./SkillCripplingShot.tres").duplicate()
	newDefinition.telegraphs = definition.telegraphs
	definition = newDefinition

func _cast(targets: Skill.TargetData) -> void:
	super._cast(targets)

	for actor in targets.perTelegraph[damageTelegraph]:
		var buff = BuffCrippled.new()
		actor.buffs.Add(buff)
