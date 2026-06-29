extends Skill
class_name IveraHumanForm

func _ready() -> void:
	Definition = load("res://game/skills/IveraHumanForm/IveraHumanForm.tres")
	super._ready()

func Cast(targets: Skill.TargetData) -> void:
	Parent.Definition = Definition.ShapeshiftTargetActor
