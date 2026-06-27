extends Skill
class_name IveraClaws

func Cast() -> void:
	var effect = IveraClawsStrikeEffect.new()
	add_child(effect)
	effect.position.y += 0.5
	effect.Play()

func GetIcon() -> Texture2D:
	return preload("res://game/Skills/IveraClaws/IveraClaws.Icon.png")

func GetTargetMode() -> TargetMode:
	return TargetMode.DirectClick
