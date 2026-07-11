extends Skill
class_name SkillStim

func _ready() -> void:
	definition = preload("./SkillStim.tres").duplicate()
	definition.telegraphs = [
		TelegraphPreset.SelfCast.new()
	]
	super._ready()

func _cast(_targets: Skill.TargetData) -> void:
	var stim = BuffStim.new()
	stim.turnsRemaining = 1
	parent.Buffs.Add(stim)
