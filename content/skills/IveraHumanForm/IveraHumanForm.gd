extends Skill
class_name IveraHumanForm

func _ready() -> void:
	definition = load("res://content/skills/IveraHumanForm/IveraHumanForm.tres").duplicate()
	definition.telegraphs = [
		TelegraphPreset.SelfCast.new()
	]
	super._ready()

func _cast(_targets: Skill.TargetData) -> void:
	parent.definition = definition.ShapeshiftTargetActor
