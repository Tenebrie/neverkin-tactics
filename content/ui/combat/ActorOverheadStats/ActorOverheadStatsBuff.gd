extends Control
class_name ActorOverheadStatsBuff

var parent: Actor

@onready var tooltipMount: Control = %TooltipMount
@onready var tooltipContainer: Control = %TooltipContainer
@onready var paradoxTooltip: ParadoxTooltip = %ParadoxTooltip
@onready var icon: TextureRect = %Icon
@onready var nameLabel: Label = %NameLabel
@onready var descriptionLabel: Label = %DescriptionLabel
@onready var durationLabel: Label = %DurationLabel

func _ready() -> void:
	set_process(false)
	tooltipContainer.position = Vector2.ZERO

func loadBuff(buff: Buff) -> void:
	icon.texture = buff.definition.iconTexture
	icon.self_modulate = getAlignmentColor(buff.definition.alignment)

	nameLabel.text = buff.definition.name
	descriptionLabel.text = parent.pronouns.evaluate(buff.definition.description)

	durationLabel.visible = true
	if buff.turnsRemaining <= -1:
		durationLabel.visible = false
	elif buff.turnsRemaining == 0:
		durationLabel.text = "Until the end of this turn"
	elif buff.turnsRemaining == 1:
		durationLabel.text = "Until the end of their next turn"
	elif buff.turnsRemaining >= 2:
		durationLabel.text = "Lasts %d more turn(s)"%buff.turnsRemaining

	mouse_entered.connect(func():
		#set_process(true)
		paradoxTooltip.visible = true
	)
	mouse_exited.connect(func():
		#set_process(false)
		paradoxTooltip.visible = false
	)

static func getAlignmentColor(alignment: Buff.Alignment) -> Color:
	match (alignment):
		Buff.Alignment.Positive: return Color.GREEN
		Buff.Alignment.Negative: return Color.RED
		_: return Color.GRAY
