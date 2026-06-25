class_name MainCamera
extends Camera3D

@export var offsetRangeMinX = 0.0
@export var offsetRangeMaxX = 0.0
@export var offsetRangeMinZ = 0.0
@export var offsetRangeMaxZ = 0.0

func _process(delta: float) -> void:
	var targetPosition := Player.Instance.position
	targetPosition.x = clamp(targetPosition.x, offsetRangeMinX, offsetRangeMaxX)
	targetPosition.y = position.y
	targetPosition.z = clamp(targetPosition.z, offsetRangeMinZ, offsetRangeMaxZ)

	position = position.lerp(targetPosition, delta * 5.0)
