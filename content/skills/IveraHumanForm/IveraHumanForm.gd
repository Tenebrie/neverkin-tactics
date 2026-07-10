extends Skill
class_name IveraHumanForm

func _ready() -> void:
	Definition = load("res://content/skills/IveraHumanForm/IveraHumanForm.tres").duplicate()
	Definition.Telegraphs = [
		TelegraphPreset.SelfCast.new()
	]
	super._ready()

func _cast(_targets: Skill.TargetData) -> void:
	Parent.Definition = Definition.ShapeshiftTargetActor
