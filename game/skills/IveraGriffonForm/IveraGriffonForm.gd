extends Skill
class_name IveraGriffonForm

func _ready() -> void:
	Definition = preload("res://game/skills/IveraGriffonForm/IveraGriffonForm.tres")
	super._ready()

func Cast(targets: Skill.TargetData) -> void:
	Parent.Definition = Definition.ShapeshiftTargetActor
	create_tween().tween_property(Parent, "global_position", targets.mousePoint, 0.3)
	await get_tree().create_timer(0.3).timeout
	for target in targets.actors:
		var effect = IveraClawsStrikeEffect.new()
		get_parent().add_child(effect)
		effect.global_transform = Transform3D.IDENTITY
		effect.global_position = target.global_position
		effect.position.y += 0.5
		effect.Play()
		target.stats.DealDamage(GetHealthDamage(target))
