extends Skill
class_name KamillaPistol

func _ready() -> void:
	Definition = preload("res://game/skills/KamillaPistol/KamillaPistol.tres")
	super._ready()

func Cast(targets: Skill.TargetData) -> void:
	pass
