extends Component
class_name ActorTargeting

@onready var agentPathPreview: AgentPath = createChild(AgentPath)
@onready var agentPathCommitted: AgentPath = createChild(AgentPath)

enum TargetMode {
	None,
	WalkPreview,
}

func _ready() -> void:
	agentPathPreview.LineColor = Color(0.0, 0.0, 0.0, 0.8)

var lockedMode: TargetMode = TargetMode.None

func _process(_delta: float) -> void:
	if parent.navigator.IsMoving():
		agentPathCommitted.SetPath(parent.navigator.agent.get_current_navigation_path(), parent.position)

	if lockedMode != TargetMode.WalkPreview:
		agentPathPreview.ClearPath()
		CombatUI.cursor.HideActionPointCost()
		return

	var previewPath := getLegalPathToMouse()
	agentPathPreview.SetPath(previewPath, parent.position)
	var apCount := parent.actions.GetMovementActionPointCost(getPathMovementCost(previewPath))
	CombatUI.cursor.ShowActionPointCost(ceil(apCount))

func _input(event: InputEvent) -> void:
	if event is not InputEventMouseButton:
		return
	var isMouseClick = event.button_index == MOUSE_BUTTON_LEFT && event.is_pressed()
	var isMouseRelease = event.button_index == MOUSE_BUTTON_LEFT && event.is_released()
	var isRightMouseDown = event.button_index == MOUSE_BUTTON_RIGHT && event.is_pressed()
	if isRightMouseDown:
		lockedMode = TargetMode.None
	elif isMouseClick:
		lockedMode = TargetMode.WalkPreview
	elif isMouseRelease && lockedMode == TargetMode.WalkPreview:
		var path := getLegalPathToMouse()
		if path.size() == 0:
			return
		var lastPoint := path[path.size() - 1]
		parent.navigator.StartMovingTowards(lastPoint)
		parent.actions.ConsumeMovement(getPathMovementCost(path))
		lockedMode = TargetMode.None

func getLegalPathToMouse() -> PackedVector3Array:
	var worldMousePos = getMouseWorldPlanePosition()
	var map_rid := parent.navigator.agent.get_navigation_map()
	var previewPath := NavigationServer3D.map_get_path(
		map_rid,
		parent.global_position,
		worldMousePos,
		true,
		parent.navigator.agent.navigation_layers
	)

	var truncatedPath := limitPathLength(previewPath, parent.actions.MovementAvailable)
	return truncatedPath

func getPathMovementCost(path: PackedVector3Array) -> float:
	var totalLength := 0.0
	for i in path.size() - 1:
		totalLength += (path[i + 1] - path[i]).length()
	return (roundf(totalLength * 1000) / 1000)

#region Utilities
func limitPathLength(points: PackedVector3Array, maxLength: float) -> PackedVector3Array:
	if points.size() < 2 or maxLength <= 0.0:
		return PackedVector3Array() if points.is_empty() else PackedVector3Array([points[0]])

	var result := PackedVector3Array([points[0]])
	var remaining := maxLength

	for i in range(1, points.size()):
		var seg := points[i] - points[i - 1]
		var seg_len := seg.length()

		if seg_len <= remaining:
			result.append(points[i])
			remaining -= seg_len
		else:
			result.append(points[i - 1] + seg * (remaining / seg_len))
			break

	return result

func getMouseWorldPlanePosition() -> Vector3:
	var camera := get_viewport().get_camera_3d()
	var mouse_pos := get_viewport().get_mouse_position()
	var origin := camera.project_ray_origin(mouse_pos)
	var direction := camera.project_ray_normal(mouse_pos)

	# Intersect with Y=0 plane
	var plane := Plane(Vector3.UP, 0.0)
	var intersection: Vector3 = plane.intersects_ray(origin, direction)

	if intersection:
		return intersection
	return Vector3.ZERO
#endregion
