extends SkillPistolShot
class_name SkillCripplingShot

func _ready() -> void:
	super._ready()
	var newDefinition = preload("./SkillCripplingShot.tres").duplicate()
	newDefinition.Telegraphs = Definition.Telegraphs
	Definition = newDefinition

func _cast(targets: Skill.TargetData) -> void:
	super._cast(targets)

	for actor in targets.perTelegraph[damageTelegraph]:
		actor.Buffs.Add(BuffCrippled.new())
