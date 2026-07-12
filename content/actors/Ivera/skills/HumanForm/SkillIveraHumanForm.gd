extends Skill
class_name IveraHumanForm

func _prepare() -> void:
	definition.telegraphs = [
		TelegraphPreset.SelfCast.new()
	]

func _cast(_targets: Skill.TargetData) -> void:
	parent.definition = definition.ShapeshiftTargetActor
