extends CanvasLayer

@onready var nameLabel: Label = %NameLabel
@onready var factionLabel: Label = %FactionLabel
@onready var threatLabel: Label = %ThreatLabel
@onready var movementSpeedLabel: Label = %MovementSpeedLabel

var trackedActor: Actor

func _ready() -> void:
	ActorHoverArea.SignalBus.MouseEntered.connect(func(actor):
		if TurnManager.Instance.CurrentActor and TurnManager.Instance.CurrentActor.Skills.SelectedSkill != null:
			return
		loadActorData(actor)
	)
	ActorHoverArea.SignalBus.MouseExited.connect(func(actor):
		if actor == trackedActor:
			trackedActor = null
	)

func _process(_delta: float):
	if TurnManager.Instance.CurrentActor and TurnManager.Instance.CurrentActor.Skills.SelectedSkill != null:
		visible = false
		trackedActor = null
		return

	if not trackedActor:
		visible = false
		return

	offset = get_viewport().get_mouse_position() - Vector2(0, $PanelContainer.size.y)
	offset.x = clampf(offset.x, 0, get_viewport().get_visible_rect().size.x - $PanelContainer.size.x)
	offset.y = clampf(offset.y, 0, get_viewport().get_visible_rect().size.y)

func loadActorData(actor: Actor):
	if actor == trackedActor:
		return

	trackedActor = actor
	nameLabel.text = actor.Definition.Name
	factionLabel.text = ActorUtils.GetFactionName(actor.Stats.Alliance)
	factionLabel.add_theme_color_override("font_color", ActorUtils.GetAllianceColor(actor.Stats.Alliance))
	threatLabel.text = ActorUtils.GetThreatLevelName(actor.Stats.ThreatCurrent)
	threatLabel.add_theme_color_override("font_color", ActorUtils.GetThreatLevelColor(actor.Stats.ThreatCurrent))

	movementSpeedLabel.visible = actor.Definition.MovementSpeedPerActionPoint > 0
	movementSpeedLabel.text = "Speed: %.1f m/a"%actor.Definition.MovementSpeedPerActionPoint

	$PanelContainer.reset_size()
	visible = true
