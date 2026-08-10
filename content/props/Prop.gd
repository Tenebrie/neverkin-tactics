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

#region Snapshots
func createSnapshot() -> Snapshot:
	return super._createSnapshot(collectDefinition: false)

func restoreSnapshot(snapshot: Variant):
	return super.restoreSnapshot(snapshot)
#endregion
