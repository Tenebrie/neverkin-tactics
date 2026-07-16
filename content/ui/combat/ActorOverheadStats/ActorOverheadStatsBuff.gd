extends Control
class_name ActorOverheadStatsBuff

var parent: Actor

@onready var tooltipMount: Control = %TooltipMount
@onready var tooltip: ActorOverheadStatsBuffTooltip = %Tooltip
@onready var icon: TextureRect = %Icon
@onready var stackCount: Label = %StackCount

func loadBuff(buff: Buff) -> void:
	icon.texture = buff.definition.iconTexture
	icon.self_modulate = getAlignmentColor(buff.definition.alignment)
	tooltip.setBuff(self, buff)
	if buff.Intensity > 1:
		stackCount.visible = true
		stackCount.text = str(buff.Intensity)
	else:
		stackCount.visible = false

	mouse_entered.connect(func():
		tooltip.visible = true
	)
	mouse_exited.connect(func():
		tooltip.visible = false
	)

static func getAlignmentColor(alignment: Buff.Alignment) -> Color:
	match (alignment):
		Buff.Alignment.Positive: return Color.GREEN
		Buff.Alignment.Negative: return Color.RED
		Buff.Alignment.Neutral: return Color.ORANGE
		_: return Color.GRAY
