@tool
extends Actor
class_name Prop

func _ready() -> void:
	if not definition:
		definition = ActorDefinition.new()
		definition.Faction = Faction.Neutral
		definition.physicalSize = 0.1
		movementSpeedPerAction = 0
		definition.PerceivedThreat = ThreatLevel.Harmless
	super._ready()

func fadeOut(_duration: float = 0.3):
	super.fadeOut()
	queue_free()
