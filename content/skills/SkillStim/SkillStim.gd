extends Skill
class_name SkillStim

func _ready() -> void:
	Definition = preload("./SkillStim.tres").duplicate()
	Definition.Telegraphs = [
		TelegraphPreset.SelfCast.new()
	]
	super._ready()

func _cast(_targets: Skill.TargetData) -> void:
	var stim = BuffStim.new()
	stim.turnsRemaining = 1
	Parent.Buffs.Add(stim)
