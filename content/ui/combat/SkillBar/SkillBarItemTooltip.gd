extends ParadoxTooltip
class_name SkillBarItemTooltip

var parent: SkillBarItem

@onready var nameLabel: Label = %Name
@onready var categoryLabel: Label = %Category
@onready var descriptionLabel: ParadoxTextLabel = %Description

var trackedSkill: Skill

func _ready():
	super()
	visibility_changed.connect(func():
		if trackedSkill and visible:
			loadDescription()
	)

func setSkill(item: SkillBarItem, skill: Skill):
	parent = item
	nameLabel.text = skill.definition.Name
	categoryLabel.text = StringUtils.getSkillCategoryString(skill.definition.Category)
	trackedSkill = skill
	if visible:
		loadDescription()

func loadDescription():
	descriptionLabel.text = StringUtils.populateSkillValues(trackedSkill.definition.Description, trackedSkill)
	updatePosition()

func updatePosition():
	if not parent:
		return
	resizeToContent()
	usesForcedPosition = true
	forcedPosition = parent.global_position - Vector2(root.size.x / 2.0 - parent.size.x / 2.0, root.size.y + 4)
