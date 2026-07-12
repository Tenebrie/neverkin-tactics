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
	agentPathPreview.LineColor = Color(0.0, 1.0, 0.0, 0.8)
	TurnManager.Instance.CurrentActorChanged.connect(func():
		resetDisplayedElements()
		lockedMode = TargetMode.None
	)

	LockedModeChanged.connect(func():
		if lockedMode != TargetMode.WalkPreview:
			resetDisplayedElements()
	)

	LockedModeChanged.emit()
	parent.Skills.SelectedSkillChanged.connect(func(skill):
		if skill is SkillMove:
			lockedMode = TargetMode.WalkPreview
	)

func _process(_delta: float) -> void:
	if TurnManager.Instance.activeActor != parent:
		return

	## Show committed path (updated per frame)
	if parent.navigator.IsMoving():
		agentPathCommitted.SetPath(parent.navigator.agent.get_current_navigation_path(), parent.position)
	else:
		agentPathCommitted.ClearPath()

	## Skill target preview
	if parent.Skills.SelectedSkill != null and parent.Skills.SelectedSkill is not SkillMove:
		return

	## Show preview path
	if lockedMode == TargetMode.WalkPreview:
		var previewPath = getLegalPathToMouse()
		agentPathPreview.SetPath(previewPath, parent.position)
		var movementCost = ActorNavigator.GetPathMovementCost(previewPath)
		var apCount = parent.actions.GetMovementActionPointCost(movementCost)
		var shownApCount = mini(apCount, parent.actions.ActionPointsAvailable)
		CombatUI.cursor.ShowActionPointCost(shownApCount, movementCost)
		PredictedActionPointCost = shownApCount

func _unhandled_input(event: InputEvent) -> void:
	if TurnManager.Instance.activeActor != parent or parent.faction != Actor.PlayerFaction:
		return

	if event is not InputEventMouseButton:
		return

	var isMouseClick = event.button_index == MOUSE_BUTTON_LEFT && event.is_pressed()
	var isMouseRelease = event.button_index == MOUSE_BUTTON_LEFT && event.is_released()
	var isRightMouseClick = event.button_index == MOUSE_BUTTON_RIGHT && event.is_pressed()
	var isRightMouseRelease = event.button_index == MOUSE_BUTTON_RIGHT && event.is_released()

	if parent.actions.IsPerformingAnyAction() and (isMouseClick or isRightMouseClick):
		parent.actions.IssueOrder_Stop()
		return

	var isSkillSelected = parent.Skills.SelectedSkill != null

	if isRightMouseClick and isSkillSelected:
		# Cancel current targeting
		lockedMode = TargetMode.None
		parent.Skills.Select(null)
	elif isMouseRelease and isSkillSelected:
		PerformAction_CastSelectedSkill()

	elif isMouseClick and lockedMode == TargetMode.WalkPreview and not isSkillSelected:
		# Cancel movement
		lockedMode = TargetMode.None
	elif isRightMouseClick and parent.isDead:
		MessageLog.PrintMessage("%s is incapacitated!"%parent.definition.Name)
	elif isRightMouseClick:
		# Start movement preview
		lockedMode = TargetMode.WalkPreview
	elif isRightMouseRelease && lockedMode == TargetMode.WalkPreview:
		# Commit movement
		var path = getLegalPathToMouse()
		if path.size() == 0:
			return
		parent.actions.IssueOrder_MoveThroughPath(path)
		lockedMode = TargetMode.None

func PerformAction_CastSelectedSkill():
	var targetData = Skill.TargetData.Collect(parent)
	await parent.actions.IssueOrder_ConfirmCast(parent.Skills.SelectedSkill, targetData)

func resetDisplayedElements() -> void:
	agentPathPreview.ClearPath()
	CombatUI.cursor.HideActionPointCost()
	PredictedActionPointCost = 0

#region Utilities
func getLegalPathToMouse() -> PackedVector3Array:
	return getLegalPathTo(parent.InputProvider.CursorPosition)

func getLegalPathTo(target: Vector3) -> PackedVector3Array:
	var map_rid = parent.navigator.agent.get_navigation_map()
	target = NavigationServer3D.map_get_closest_point(map_rid, target)

	var previewPath = NavigationServer3D.map_get_path(
			map_rid,
			parent.global_position,
			target,
			true,
			parent.navigator.agent.navigation_layers
	)
	var truncatedPath = ActorUtils.limitPathLength(previewPath, parent.actions.MovementAvailable)
	return truncatedPath

#endregion
