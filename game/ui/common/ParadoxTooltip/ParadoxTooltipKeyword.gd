extends ParadoxTooltip
class_name ParadoxTooltipKeyword

@onready var nameLabel: Label = %Name
@onready var categoryLabel: Label = %Category
@onready var descriptionLabel: ParadoxTextLabel = %Description

func setKeyword(keyword: KeywordDefinition):
	nameLabel.text = keyword.name
	categoryLabel.text = keyword.category
	if keyword.source == KeywordDefinition.Source.Native:
		descriptionLabel.text = StringUtils.populateActorValues(keyword.description, TurnManager.Instance.activePlayerActor)
	elif keyword.source == KeywordDefinition.Source.Skill:
		TurnManager.Instance.activePlayerActor.Skills.Simulate(keyword.sourceScript, func(skill: Skill):
			descriptionLabel.text = StringUtils.populateSkillValues(keyword.description, skill)
		)
	elif keyword.source == KeywordDefinition.Source.Buff:
		TurnManager.Instance.activePlayerActor.buffs.Simulate(keyword.sourceScript, func(buff: Buff):
			descriptionLabel.text = StringUtils.populateBuffValues(keyword.description, buff)
			return
		)

	nameLabel.add_theme_color_override("font_color", keyword.color)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("lockParadoxTooltipNested"):
		lockTooltip()
		get_viewport().set_input_as_handled()
