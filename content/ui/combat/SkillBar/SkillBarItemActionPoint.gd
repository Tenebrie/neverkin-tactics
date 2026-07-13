extends Control
class_name SkillBarItemActionPoint

func setColor(color: Color):
	var stylebox = get_theme_stylebox("panel") as StyleBoxFlat
	stylebox.bg_color = color
	add_theme_stylebox_override("panel", stylebox)
