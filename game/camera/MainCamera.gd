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

var isDragging = false
var dragAnchor: Vector3

static var Instance: MainCamera

func _ready() -> void:
	Instance = self
	targetZoom = size
	cameraTarget = position
	position = Vector3(-1000, position.y, -1000)
	add_child(CameraMotionBlur.new())
	TurnManager.Instance.CurrentActorChanged.connect(func(_a):
		var actor = TurnManager.Instance.activeActor
		if actor != null:
			if position.distance_to(cameraTarget) > 50:
				snapToTarget(actor.global_position)
				position = cameraTarget
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
	elif button.button_index == MOUSE_BUTTON_MIDDLE:
		if canDrag():
			isDragging = true
			dragAnchor = groundPoint(button.position)

func canDrag() -> bool:
	if lockedTarget != null:
		return false
	if TurnManager.Instance.activeFaction != Actor.PlayerFaction:
		return false
	return TurnManager.Instance.activePlayerActor != null

func groundPoint(screenPos: Vector2) -> Vector3:
	var hit: Vector3 = Plane(Vector3.UP, 0.0).intersects_ray(project_ray_origin(screenPos), project_ray_normal(screenPos))
	if hit == null:
		return Vector3(cameraTarget.x, 0.0, cameraTarget.z)
	return hit

func updateDrag() -> void:
	if not isDragging:
		return
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
		isDragging = false
		return
	var current = groundPoint(get_viewport().get_mouse_position())
	cameraTarget.x = position.x + dragAnchor.x - current.x
	cameraTarget.z = position.z + dragAnchor.z - current.z

func _process(delta: float) -> void:
	size = lerpf(size, targetZoom, delta * 10.0)
	if TurnManager.Instance.activePlayerActor == null:
		return

	var isPlayerTurn = TurnManager.Instance.activeFaction == Actor.PlayerFaction
	updateDrag()

	var isMovingKeyboard = false
	if lockedTarget:
		cameraTarget = lockedTarget.global_position
	elif isPlayerTurn:
		var movementVector = Vector3.ZERO
		if Input.is_key_pressed(KEY_W):
			movementVector.z -= 1
		if Input.is_key_pressed(KEY_S):
			movementVector.z += 1
		if Input.is_key_pressed(KEY_A):
			movementVector.x -= 1
		if Input.is_key_pressed(KEY_D):
			movementVector.x += 1
		movementVector = movementVector.normalized() * 1.2
		cameraTarget += movementVector * delta * size
		if movementVector.length() > 0:
			isMovingKeyboard = true
	elif TurnManager.Instance.activeActor:
		cameraTarget = TurnManager.Instance.activeActor.global_position

	cameraTarget.x = clampf(cameraTarget.x, offsetRangeMinX, offsetRangeMaxX)
	cameraTarget.z = clampf(cameraTarget.z, offsetRangeMinZ, offsetRangeMaxZ)
	var targetPosition = Vector3(cameraTarget.x, position.y, cameraTarget.z)
	if isMovingKeyboard:
		var lerpSpeed = 200.0
		position = position.lerp(targetPosition, minf(delta * lerpSpeed, 1.0))
	elif isDragging:
		var lerpSpeed = 200.0
		position = position.lerp(targetPosition, minf(delta * lerpSpeed, 1.0))
	else:
		var lerpSpeed = 12.0 if isPlayerTurn and not lockedTarget else 5.0
		position = position.lerp(targetPosition, minf(delta * lerpSpeed, 1.0))

static var lockedTarget: Node3D
static func lock(node: Node3D):
	lockedTarget = node
	await Instance.get_tree().create_timer(1.0).timeout

static func unlock(node: Node3D = null):
	if lockedTarget == node or node == null:
		lockedTarget = null
	await Instance.get_tree().create_timer(0.5).timeout
