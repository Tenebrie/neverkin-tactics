extends Component
class_name ActorTargeting

@onready var agentPathPreview: AgentPath = createChild(AgentPath)
@onready var agentPathCommitted: AgentPath = createChild(AgentPath)

var PredictedActionPointCost: int = 0

enum TargetMode {
	None,
	WalkPreview,
}

var lockedMode: TargetMode = TargetMode.None:
	set(v):
		lockedMode = v
		LockedModeChanged.emit()
signal LockedModeChanged

func _parentReady() -> void:
	agentPathPreview.LineColor = Color(0.0, 0.0, 0.0, 0.8)
	TurnManager.Instance.CurrentActorChanged.connect(func():
		resetDisplayedElements()
		lockedMode = TargetMode.None
	)

	LockedModeChanged.connect(func():
		if lockedMode != TargetMode.WalkPreview:
			resetDisplayedElements()
	)

	LockedModeChanged.emit()
	Parent.Skills.SelectedSkillChanged.connect(func(skill):
		if skill is SkillMove:
			lockedMode = TargetMode.WalkPreview
	)

func _process(_delta: float) -> void:
	if not Parent.IsPlayerControlled:
		return

	## Show committed path (updated per frame)
	if Parent.navigator.IsMoving():
		agentPathCommitted.SetPath(Parent.navigator.agent.get_current_navigation_path(), Parent.position)
	else:
		agentPathCommitted.ClearPath()

	## Skill target preview
	if Parent.Skills.SelectedSkill != null and Parent.Skills.SelectedSkill is not SkillMove:
		return

	## Show preview path
	if lockedMode == TargetMode.WalkPreview:
		var previewPath := getLegalPathToMouse()
		agentPathPreview.SetPath(previewPath, Parent.position)
		var movementCost = ActorNavigator.GetPathMovementCost(previewPath)
		var apCount := Parent.actions.GetMovementActionPointCost(movementCost)
		var shownApCount := mini(apCount, Parent.actions.ActionPointsAvailable)
		CombatUI.cursor.ShowActionPointCost(shownApCount, movementCost)
		PredictedActionPointCost = shownApCount

func _unhandled_input(event: InputEvent) -> void:
	if not Parent.IsPlayerControlled:
		return

	if event is not InputEventMouseButton:
		return

	var isMouseClick = event.button_index == MOUSE_BUTTON_LEFT && event.is_pressed()
	var isMouseRelease = event.button_index == MOUSE_BUTTON_LEFT && event.is_released()
	var isRightMouseClick = event.button_index == MOUSE_BUTTON_RIGHT && event.is_pressed()
	var isRightMouseRelease = event.button_index == MOUSE_BUTTON_RIGHT && event.is_released()

	if Parent.actions.IsPerformingAnyAction() and (isMouseClick or isRightMouseClick):
		Parent.actions.IssueOrder_Stop()
		return

	var isSkillSelected = Parent.Skills.SelectedSkill != null

	if isRightMouseClick and isSkillSelected:
		# Cancel current targeting
		lockedMode = TargetMode.None
		Parent.Skills.Select(null)
	elif isMouseRelease and isSkillSelected:
		PerformAction_CastSelectedSkill()

	elif isMouseClick and lockedMode == TargetMode.WalkPreview and not isSkillSelected:
		# Cancel movement
		lockedMode = TargetMode.None
	elif isRightMouseClick and Parent.isDead:
		MessageLog.PrintMessage("%s is incapacitated!"%Parent.Definition.Name)
	elif isRightMouseClick:
		# Start movement preview
		lockedMode = TargetMode.WalkPreview
	elif isRightMouseRelease && lockedMode == TargetMode.WalkPreview:
		# Commit movement
		var path = getLegalPathToMouse()
		if path.size() == 0:
			return
		Parent.actions.IssueOrder_MoveThroughPath(path)
		lockedMode = TargetMode.None

func PerformAction_CastSelectedSkill():
	var targetData = Skill.TargetData.Collect(Parent)
	Parent.actions.IssueOrder_ConfirmCast(Parent.Skills.SelectedSkill, targetData)

func resetDisplayedElements() -> void:
	agentPathPreview.ClearPath()
	CombatUI.cursor.HideActionPointCost()
	PredictedActionPointCost = 0

#region Utilities
func getLegalPathToMouse() -> PackedVector3Array:
	return getLegalPathTo(Parent.InputProvider.CursorPosition)

func getLegalPathTo(target: Vector3) -> PackedVector3Array:
	var map_rid := Parent.navigator.agent.get_navigation_map()
	target = NavigationServer3D.map_get_closest_point(map_rid, target)

	var previewPath = NavigationServer3D.map_get_path(
			map_rid,
			Parent.global_position,
			target,
			true,
			Parent.navigator.agent.navigation_layers
	)
	var truncatedPath = ActorUtils.limitPathLength(previewPath, Parent.actions.MovementAvailable)
	return truncatedPath

#endregion
