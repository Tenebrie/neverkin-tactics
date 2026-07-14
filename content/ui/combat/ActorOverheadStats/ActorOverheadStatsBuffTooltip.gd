extends ParadoxTooltip
class_name ActorOverheadStatsBuffTooltip

@onready var nameLabel: Label = %Name
@onready var categoryLabel: Label = %Category
@onready var descriptionLabel: ParadoxTextLabel = %Description

func setBuff(_item: ActorOverheadStatsBuff, buff: Buff):
	nameLabel.text = buff.definition.name
	categoryLabel.text = "Status"
	descriptionLabel.text  = StringUtils.populateBuffValues(buff.definition.description, buff)

	#resizeToContent()
	#usesForcedPosition = true
	#forcedPosition = item.global_position - Vector2(root.size.x / 2.0 - item.size.x / 2.0, root.size.y + 4)
