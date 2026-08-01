extends Component
class_name ActorNavigator

signal stopped

@onready var agent: NavigationAgent3D = parent.get_node("NavigationAgent3D")

#var maxMovementSpeed = 3.6
var maxAcceleration = 40.0
var maxDeceleration = 40.0
var movementSpeed = Vector3.ZERO
const HomingDistance = 0.3

# Non-combat
#var maxMovementSpeed = 0.8
#var maxDeceleration = 6.0

func _parentReady() -> void:
	agent.target_position = parent.global_position

func StartMovingTowards(target: Vector3) -> void:
	target.y = 0.0
	var map = agent.get_navigation_map()
	target = NavigationServer3D.map_get_closest_point(map, target)
	agent.target_position = target
	var toTarget = target - parent.global_position
	toTarget.y = 0.0
	if toTarget.length() < 0.001:
		stopped.emit.call_deferred()
	elif toTarget.length() <= HomingDistance:
		movementSpeed = toTarget.normalized() * 0.4

func IsPathable(target: Vector3) -> bool:
	target.y = 0.0
	var map = agent.get_navigation_map()
	var adjustedTarget = NavigationServer3D.map_get_closest_point(map, target)
	return target.distance_squared_to(adjustedTarget) < 0.05

func IsMoving() -> bool:
	return parent.velocity.length() > 0.001 or movementSpeed.length() > 0.001

func Stop():
	agent.target_position = parent.position

func HardStop():
	if agent.is_navigation_finished() and abs(movementSpeed.x) < 0.001 and abs(movementSpeed.z) < 0.001:
		return
	agent.target_position = parent.position
	agent.get_next_path_position()
	movementSpeed = Vector3.ZERO
	parent.velocity = Vector3.ZERO
	stopped.emit()

func _process(delta: float) -> void:
	if agent.is_navigation_finished():
		_processDeceleration(delta)
		return

	var nextPathPosition = agent.get_next_path_position()
	var direction = parent.global_position.direction_to(nextPathPosition)
	direction.y = 0.0
	direction = direction.normalized()

	var maxMovementSpeed = clampf(parent.movementSpeedPerAction / 2, 2.0, 4.0)
	var distanceToTarget = parent.global_position.distance_to(agent.target_position)
	var targetSpeed = minf(maxMovementSpeed, sqrt(2.0 * maxDeceleration * distanceToTarget))

	movementSpeed = movementSpeed.lerp(direction * targetSpeed, maxAcceleration * delta)
	movementSpeed.y = 0.0

	parent.velocity.x = movementSpeed.x
	parent.velocity.z = movementSpeed.z
	parent.velocity.y = 0.0
	parent.move_and_slide()
	SignalBus.ActorTraversed.emit(parent, movementSpeed.length() * delta)

func _processDeceleration(delta: float) -> void:
	if abs(movementSpeed.x) < 0.001 and abs(movementSpeed.z) < 0.001:
		return

	var toTarget = agent.target_position - parent.global_position
	toTarget.y = 0.0
	var remaining = toTarget.length()

	if remaining > HomingDistance:
		movementSpeed = Vector3.ZERO
		parent.velocity = Vector3.ZERO
		stopped.emit()
		return

	var speed = clampf(sqrt(2.0 * maxDeceleration * remaining), 0.4, maxf(movementSpeed.length(), 0.4))
	if remaining <= speed * delta:
		parent.global_position = Vector3(agent.target_position.x, parent.global_position.y, agent.target_position.z)
		SignalBus.ActorTraversed.emit(parent, remaining)
		movementSpeed = Vector3.ZERO
		parent.velocity = Vector3.ZERO
		stopped.emit()
		return

	movementSpeed = toTarget * (speed / remaining)
	parent.velocity = Vector3.ZERO
	var next = parent.global_position + movementSpeed * delta
	var onMesh = NavigationServer3D.map_get_closest_point(agent.get_navigation_map(), next)
	parent.global_position = Vector3(onMesh.x, parent.global_position.y, onMesh.z)
	SignalBus.ActorTraversed.emit(parent, speed * delta)

	var newRemaining = Vector3(agent.target_position.x - parent.global_position.x, 0.0, agent.target_position.z - parent.global_position.z).length()
	if newRemaining >= remaining:
		parent.global_position = Vector3(agent.target_position.x, parent.global_position.y, agent.target_position.z)
		SignalBus.ActorTraversed.emit(parent, newRemaining)
		movementSpeed = Vector3.ZERO
		stopped.emit()

static func GetPathMovementCost(path: PackedVector3Array) -> float:
	var totalLength = 0.0
	for i in path.size() - 1:
		totalLength += (path[i + 1] - path[i]).length()
	return (roundf(totalLength * 1000) / 1000)

func GetRemainingPathLength() -> float:
	var navPath = agent.get_current_navigation_path()
	if navPath.size() < 2:
		return 0.0
	var idx: int = agent.get_current_navigation_path_index()
	idx = clampi(idx, 0, navPath.size() - 1)
	var pos = parent.global_position
	var total = pos.distance_to(navPath[idx])
	for i in range(idx, navPath.size() - 1):
		total += navPath[i].distance_to(navPath[i + 1])
	return total

static var SignalBus: SignalBusImplementation = SignalBusImplementation.new()
class SignalBusImplementation extends NodeSignalBus:
	signal ActorTraversed(actor: Actor, distance: float)
