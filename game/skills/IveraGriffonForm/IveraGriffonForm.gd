extends Skill
class_name IveraGriffonForm

func _ready() -> void:
	Definition = preload("res://game/skills/IveraGriffonForm/IveraGriffonForm.tres")
	super._ready()

func Cast(targets: Skill.TargetData) -> void:
	Parent.Definition = Definition.ShapeshiftTargetActor
	create_tween().tween_property(Parent, "global_position", targets.mousePoint, 0.3)
