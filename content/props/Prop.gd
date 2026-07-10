@tool
extends Actor
class_name Prop

@export var Name: String = "Unnamed Prop"

func _ready() -> void:
	Definition = ActorDefinition.new()
	Definition.Name = Name
	Definition.Faction = Faction.Neutral
	Definition.physicalSize = 0.1
	movementSpeedPerAction = 0
	Definition.PerceivedThreat = ThreatLevel.Harmless
	super._ready()

func fadeOut(_duration: float = 0.3):
	super.fadeOut()
	queue_free()
