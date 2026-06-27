class_name MainCamera
extends Camera3D

@export var offsetRangeMinX = 0.0
@export var offsetRangeMaxX = 0.0
@export var offsetRangeMinZ = 0.0
@export var offsetRangeMaxZ = 0.0

func _process(delta: float) -> void:
	if TurnManager.Instance.CurrentActor == null:
		return
	var targetPosition := TurnManager.Instance.CurrentActor.position
	targetPosition.x = clamp(targetPosition.x, offsetRangeMinX, offsetRangeMaxX)
	targetPosition.y = position.y
	targetPosition.z = clamp(targetPosition.z, offsetRangeMinZ, offsetRangeMaxZ)

	position = position.lerp(targetPosition, delta * 5.0)
