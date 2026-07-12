extends ParadoxTooltip
class_name ParadoxTooltipKeyword

@onready var nameLabel: Label = %Name
@onready var categoryLabel: Label = %Category
@onready var descriptionLabel: ParadoxTextLabel = %Description

func setKeyword(keyword: KeywordDefinition):
	nameLabel.text = keyword.name
	categoryLabel.text = keyword.category
	descriptionLabel.text = keyword.description
	nameLabel.add_theme_color_override("font_color", keyword.color)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("lockParadoxTooltipNested"):
		lockTooltip()
		get_viewport().set_input_as_handled()
