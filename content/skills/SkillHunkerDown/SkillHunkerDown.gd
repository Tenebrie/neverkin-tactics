extends Skill
class_name SkillHunkerDown

func _ready() -> void:
	definition = preload("./SkillHunkerDown.tres").duplicate()
	super._ready()
