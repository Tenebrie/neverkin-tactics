class_name MainCamera
extends Camera3D

@export var offsetRangeMinX = 0.0
@export var offsetRangeMaxX = 0.0
@export var offsetRangeMinZ = 0.0
@export var offsetRangeMaxZ = 0.0

@export var zoomMin = 5.0
@export var zoomMax = 30.0
@export var zoomStep = 2.0

var cameraTarget: Vector3
var targetZoom: float

func _ready() -> void:
	targetZoom = size
	cameraTarget = position
	TurnManager.Instance.CurrentActorChanged.connect(func(_a):
		var actor = TurnManager.Instance.activeActor
		if actor != null:
			snapToTarget(actor.global_position)
	)

func snapToTarget(worldPos: Vector3) -> void:
	cameraTarget.x = clampf(worldPos.x, offsetRangeMinX, offsetRangeMaxX)
	cameraTarget.z = clampf(worldPos.z, offsetRangeMinZ, offsetRangeMaxZ)

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
	if TurnManager.Instance.activePlayerActor == null:
		return

	var isPlayerTurn = TurnManager.Instance.activeFaction == Actor.PlayerFaction

	if isPlayerTurn:
		var movementVector = Vector3.ZERO
		if Input.is_key_pressed(KEY_W):
			movementVector.z -= 1
		if Input.is_key_pressed(KEY_S):
			movementVector.z += 1
		if Input.is_key_pressed(KEY_A):
			movementVector.x -= 1
		if Input.is_key_pressed(KEY_D):
			movementVector.x += 1
		movementVector = movementVector.normalized()
		cameraTarget += movementVector * delta * size
	elif TurnManager.Instance.activeActor:
		cameraTarget = TurnManager.Instance.activeActor.global_position

	cameraTarget.x = clampf(cameraTarget.x, offsetRangeMinX, offsetRangeMaxX)
	cameraTarget.z = clampf(cameraTarget.z, offsetRangeMinZ, offsetRangeMaxZ)
	var targetPosition = Vector3(cameraTarget.x, position.y, cameraTarget.z)
	var lerpSpeed = 12.0 if isPlayerTurn else 5.0
	position = position.lerp(targetPosition, delta * lerpSpeed)
