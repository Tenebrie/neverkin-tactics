extends SkillPistolShot
class_name SkillCripplingShot

func _ready() -> void:
	super._ready()
	var newDefinition = preload("./SkillCripplingShot.tres").duplicate()
	newDefinition.Telegraphs = Definition.Telegraphs
	Definition = newDefinition

func Cast(targets: Skill.TargetData) -> void:
	super.Cast(targets)

	for actor in targets.PerTelegraph[damageTelegraph]:
		actor.Buffs.Add(BuffCrippled.new())
