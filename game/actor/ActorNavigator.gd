extends Component
class_name ActorNavigator

@onready var agent: NavigationAgent3D = parent.get_node("NavigationAgent3D")

var maxMovementSpeed := 1.8
var maxAcceleration := 20.0
var maxDeceleration := 20.0
var movementSpeed := Vector3.ZERO

# Non-combat
#var maxMovementSpeed := 0.8
#var maxDeceleration := 6.0

func StartMovingTowards(target: Vector3) -> void:
	target.y = 0.1
	var map := agent.get_navigation_map()
	target = NavigationServer3D.map_get_closest_point(map, target)
	agent.target_position = target

func IsPathable(target: Vector3) -> bool:
	target.y = 0.1
	var map := agent.get_navigation_map()
	var adjustedTarget := NavigationServer3D.map_get_closest_point(map, target)
	return target.distance_squared_to(adjustedTarget) < 0.05

func IsMoving() -> bool:
	return parent.velocity.length() > 0.001

func Stop():
	agent.target_position = parent.position

func HardStop():
	agent.target_position = parent.position
	agent.get_next_path_position()

func _process(delta: float) -> void:
	if agent.is_navigation_finished():
		var horizontal := Vector3(movementSpeed.x, 0.0, movementSpeed.z)
		horizontal = horizontal.move_toward(Vector3.ZERO, maxDeceleration * delta)
		movementSpeed.x = horizontal.x
		movementSpeed.z = horizontal.z
		parent.velocity.x = movementSpeed.x
		parent.velocity.z = movementSpeed.z
		parent.velocity.y = 0.0
		parent.move_and_slide()
		parent.velocity = Vector3.ZERO
		return

	var nextPathPosition := agent.get_next_path_position()
	var direction := parent.global_position.direction_to(nextPathPosition)
	direction.y = 0.0
	direction = direction.normalized()

	var distanceToTarget := parent.global_position.distance_to(agent.target_position)
	var stopDistance := maxf(distanceToTarget - agent.target_desired_distance, 0.0)
	var targetSpeed := minf(maxMovementSpeed, sqrt(2.0 * maxDeceleration * stopDistance))

	movementSpeed = movementSpeed.lerp(direction * targetSpeed, maxAcceleration * delta)
	movementSpeed.y = 0.0

	parent.velocity.x = movementSpeed.x
	parent.velocity.z = movementSpeed.z
	parent.velocity.y = 0.0
	parent.move_and_slide()

static func GetPathMovementCost(path: PackedVector3Array) -> float:
	var totalLength := 0.0
	for i in path.size() - 1:
		totalLength += (path[i + 1] - path[i]).length()
	return (roundf(totalLength * 1000) / 1000)

func GetRemainingPathLength() -> float:
	var navPath := agent.get_current_navigation_path()
	if navPath.size() < 2:
		return 0.0
	var idx: int = agent.get_current_navigation_path_index()
	idx = clampi(idx, 0, navPath.size() - 1)
	var pos := parent.global_position
	var total := pos.distance_to(navPath[idx])
	for i in range(idx, navPath.size() - 1):
		total += navPath[i].distance_to(navPath[i + 1])
	return total
