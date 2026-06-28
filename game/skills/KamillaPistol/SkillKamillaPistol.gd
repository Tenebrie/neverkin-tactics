extends Skill
class_name SkillKamillaPistol

func _ready() -> void:
	Definition = preload("res://game/skills/KamillaPistol/SkillKamillaPistol.tres")
	super._ready()

func Cast(targets: Skill.TargetData) -> void:
	pass
