extends ParadoxTooltip
class_name SkillBarItemTooltip

@onready var nameLabel: Label = %Name
@onready var categoryLabel: Label = %Category
@onready var descriptionLabel: ParadoxTextLabel = %Description

func setSkill(item: SkillBarItem, skill: Skill):
	nameLabel.text = skill.definition.Name
	categoryLabel.text = StringUtils.getSkillCategoryString(skill.definition.Category)
	descriptionLabel.text = StringUtils.populateSkillValues(skill.definition.Description, skill)

	resizeToContent()
	usesForcedPosition = true
	forcedPosition = item.global_position - Vector2(root.size.x / 2.0 - item.size.x / 2.0, root.size.y + 4)
