extends Component
class_name ActorTargeting

@onready var agentPathPreview: AgentPath = createChild(AgentPath)
@onready var agentPathCommitted: AgentPath = createChild(AgentPath)

var PredictedActionPointCost: int = 0

enum TargetMode {
	None,
	WalkPreview,
}

var lockedMode: TargetMode = TargetMode.None
signal LockedModeChanged

func _ready() -> void:
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

func _process(_delta: float) -> void:
	if not parent.IsPlayerControlled:
		return

	## Show committed path (updated per frame)
	if parent.navigator.IsMoving():
		agentPathCommitted.SetPath(parent.navigator.agent.get_current_navigation_path(), parent.position)
	else:
		agentPathCommitted.ClearPath()

	## Skill target preview
	if parent.Skills.SelectedSkill != null:
		return

	## Show preview path
	if lockedMode == TargetMode.WalkPreview:
		var previewPath := getLegalPathToMouse()
		agentPathPreview.SetPath(previewPath, parent.position)
		var apCount := parent.actions.GetMovementActionPointCost(ActorNavigator.GetPathMovementCost(previewPath))
		var shownApCount := mini(apCount, parent.actions.ActionPointsAvailable)
		CombatUI.cursor.ShowActionPointCost(shownApCount)
		PredictedActionPointCost = shownApCount

func _unhandled_input(event: InputEvent) -> void:
	if not parent.IsPlayerControlled:
		return

	if event is not InputEventMouseButton:
		return

	var isMouseClick = event.button_index == MOUSE_BUTTON_LEFT && event.is_pressed()
	var isMouseRelease = event.button_index == MOUSE_BUTTON_LEFT && event.is_released()
	var isRightMouseDown = event.button_index == MOUSE_BUTTON_RIGHT && event.is_pressed()

	if parent.actions.IsPerformingAnyAction():
		parent.actions.IssueOrder_Stop()
		return

	var isSkillSelected = parent.Skills.SelectedSkill != null

	if isRightMouseDown:
		# Cancel current targeting
		lockedMode = TargetMode.None
		parent.Skills.Select(null)
	elif isMouseClick and isSkillSelected:
		# Cast selected skill
		var targetData = Skill.TargetData.new()
		if TelegraphManager.Instance.Targets.size() > 0:
			targetData.actor = TelegraphManager.Instance.Targets.get(0)
		targetData.actors = TelegraphManager.Instance.Targets
		targetData.exclusionActors = TelegraphManager.Instance.ExclusionTargets
		targetData.mousePoint = ActorUtils.GetMouseWorldPlanePosition(get_viewport())
		parent.actions.IssueOrder_Cast(parent.Skills.SelectedSkill, targetData)
		if parent.actions.ActionPointsAvailable < parent.Skills.SelectedSkill.ActionPointCost \
			or not parent.Skills.Has(parent.Skills.SelectedSkill.get_script()):
			parent.Skills.Select(null)
	elif isMouseClick:
		# Start movement preview
		lockedMode = TargetMode.WalkPreview
	elif isMouseRelease && lockedMode == TargetMode.WalkPreview:
		# Commit movement
		var path := getLegalPathToMouse()
		if path.size() == 0:
			return
		parent.actions.IssueOrder_MoveTo(path)
		lockedMode = TargetMode.None

	LockedModeChanged.emit()

func resetDisplayedElements() -> void:
	agentPathPreview.ClearPath()
	CombatUI.cursor.HideActionPointCost()
	PredictedActionPointCost = 0

#region Utilities
func getLegalPathToMouse() -> PackedVector3Array:
	var worldMousePos = ActorUtils.GetMouseWorldPlanePosition(get_viewport())
	var map_rid := parent.navigator.agent.get_navigation_map()
	var previewPath := NavigationServer3D.map_get_path(
		map_rid,
		parent.global_position,
		worldMousePos,
		true,
		parent.navigator.agent.navigation_layers
	)

	var truncatedPath := ActorUtils.LimitPathLength(previewPath, parent.actions.MovementAvailable)
	return truncatedPath
#endregion
