extends ParadoxTooltip
class_name SkillBarItemTooltip

var parent: SkillBarItem

@onready var nameLabel: Label = %Name
@onready var categoryLabel: Label = %Category
@onready var descriptionLabel: ParadoxTextLabel = %Description

func setSkill(item: SkillBarItem, skill: Skill):
	parent = item
	nameLabel.text = skill.definition.Name
	categoryLabel.text = StringUtils.getSkillCategoryString(skill.definition.Category)
	descriptionLabel.text = StringUtils.populateSkillValues(skill.definition.Description, skill)
	updatePosition()

func updatePosition():
	if not parent:
		return
	resizeToContent()
	usesForcedPosition = true
	forcedPosition = parent.global_position - Vector2(root.size.x / 2.0 - parent.size.x / 2.0, root.size.y + 4)
