extends Control
class_name ActorOverheadStatsBuff

var parent: Actor

@onready var tooltipMount: Control = %TooltipMount
@onready var tooltipContainer: Control = %TooltipContainer
@onready var icon: TextureRect = %Icon
@onready var nameLabel: Label = %NameLabel
@onready var descriptionLabel: Label = %DescriptionLabel
@onready var durationLabel: Label = %DurationLabel

func _ready() -> void:
	set_process(false)
	tooltipContainer.visible = false

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
		set_process(true)
		tooltipContainer.visible = true
	)
	mouse_exited.connect(func():
		set_process(false)
		tooltipContainer.visible = false
	)

func _process(_d) -> void:
	tooltipContainer.global_position = get_viewport().get_mouse_position() - Vector2(0, tooltipContainer.size.y)
	tooltipContainer.global_position.x = clampf(tooltipContainer.global_position.x, 0, get_viewport().get_visible_rect().size.x - tooltipContainer.size.x)
	tooltipContainer.global_position.y = clampf(tooltipContainer.global_position.y, 0, get_viewport().get_visible_rect().size.y)

static func getAlignmentColor(alignment: Buff.Alignment) -> Color:
	match (alignment):
		Buff.Alignment.Positive: return Color.GREEN
		Buff.Alignment.Negative: return Color.RED
		_: return Color.GRAY
