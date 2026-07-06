extends Skill
class_name SkillHunkerDown

func _ready() -> void:
	Definition = preload("./SkillHunkerDown.tres").duplicate()
	super._ready()
