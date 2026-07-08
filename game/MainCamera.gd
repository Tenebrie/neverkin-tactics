class_name MainCamera
extends Camera3D

@export var offsetRangeMinX = 0.0
@export var offsetRangeMaxX = 0.0
@export var offsetRangeMinZ = 0.0
@export var offsetRangeMaxZ = 0.0

@export var zoomMin = 5.0
@export var zoomMax = 30.0
@export var zoomStep = 2.0

var userOffset: Vector3
var targetZoom: float

func _ready() -> void:
	targetZoom = size
	TurnManager.Instance.CurrentActorChanged.connect(func(_a):
		userOffset = Vector3.ZERO
	)

func _unhandled_input(event: InputEvent) -> void:
	var button = event as InputEventMouseButton
	if button == null or not button.pressed:
		return
	if button.button_index == MOUSE_BUTTON_WHEEL_UP:
		targetZoom = clampf(targetZoom - zoomStep, zoomMin, zoomMax)
	elif button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		targetZoom = clampf(targetZoom + zoomStep, zoomMin, zoomMax)

func _process(delta: float) -> void:
	size = lerpf(size, targetZoom, delta * 10.0)

	if TurnManager.Instance.CurrentActor == null:
		return

	var movementVector = Vector3.ZERO
	if TurnManager.Instance.CurrentFaction == Actor.Faction.Player:
		if Input.is_key_pressed(KEY_W):
			movementVector.z -= 1
		if Input.is_key_pressed(KEY_S):
			movementVector.z += 1
		if Input.is_key_pressed(KEY_A):
			movementVector.x -= 1
		if Input.is_key_pressed(KEY_D):
			movementVector.x += 1
	movementVector = movementVector.normalized()
	userOffset += movementVector * delta * size

	var actorPos = TurnManager.Instance.ActorTakingTurn.global_position

	var clampedX = clampf(actorPos.x + userOffset.x, offsetRangeMinX, offsetRangeMaxX)
	var clampedZ = clampf(actorPos.z + userOffset.z, offsetRangeMinZ, offsetRangeMaxZ)

	userOffset.x = clampedX - actorPos.x
	userOffset.z = clampedZ - actorPos.z

	var targetPosition = Vector3(clampedX, position.y, clampedZ)
	var lerpSpeed = 12.0 if TurnManager.Instance.CurrentFaction == Actor.Faction.Player else 5.0
	position = position.lerp(targetPosition, delta * lerpSpeed)
