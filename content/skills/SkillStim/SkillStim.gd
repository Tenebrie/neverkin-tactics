extends Skill
class_name SkillStim

func _ready() -> void:
	Definition = preload("./SkillStim.tres").duplicate()
	Definition.Telegraphs = [
		TelegraphPreset.SelfCast.new()
	]
	super._ready()

func Cast(_targets: Skill.TargetData) -> void:
	Parent.Buffs.Add(BuffStim.new())
