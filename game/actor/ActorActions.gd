extends Component
class_name ActorActions

signal ActionPointsChanged(current: int)
signal MovementPointsChanged(current: float)

var ActionPointsUsed: int = 0
var ActionPointsSaved: int = 0

var ActionPointsMax: int:
	get: return parent.Definition.ActionPointsMax

var ActionPointsAvailable: int:
	get:
		return ActionPointsMax - ActionPointsUsed + ActionPointsSaved

var _actionPointsThreatenedFromSkill: int = 0
var ActionPointsThreatened: int:
	get:
		return _actionPointsThreatenedFromSkill

func ConsumeActionPoints(value: int):
	while ActionPointsSaved > 0 && value > 0:
		value -= 1
		ActionPointsSaved -= 1
	ActionPointsUsed += value
	ActionPointsChanged.emit(ActionPointsAvailable)

func RefundActionPoints(value: int):
	while ActionPointsUsed > 0 && value > 0:
		value -= 1
		ActionPointsUsed -= 1
	ActionPointsSaved += value
	ActionPointsChanged.emit(ActionPointsAvailable)

#region Movement
@export var MovementSpeedPerAP: float = 1.0
var MovementBuffer: float = 0.0:
	set(v):
		MovementBuffer = v
		MovementPointsChanged.emit(v)
var MovementAvailable: float:
	get:
		return MovementBuffer + MovementSpeedPerAP * ActionPointsAvailable

func _parentReady() -> void:
	parent.Skills.SelectedSkillChanged.connect(func(skill):
		if skill:
			_actionPointsThreatenedFromSkill = skill.Definition.ActionPointCost
		else:
			_actionPointsThreatenedFromSkill = 0
	)
	TurnManager.Instance.PlayerTurnStarted.connect(onTurnStarted)

func ConsumeMovement(value: float):
	for i in 50:
		if value <= MovementBuffer:
			MovementBuffer -= value
			return
		MovementBuffer += MovementSpeedPerAP
		ConsumeActionPoints(1)

		if ActionPointsAvailable < 0:
			MovementBuffer = 0.0
			ActionPointsUsed = ActionPointsMax
			return

func RefundMovement(value: float):
	MovementBuffer += value
	for i in 50:
		if MovementBuffer < MovementSpeedPerAP:
			return
		if ActionPointsUsed == 0:
			return
		MovementBuffer -= MovementSpeedPerAP
		RefundActionPoints(1)

func GetMovementActionPointCost(value: float) -> int:
	return maxi(0, ceil((value - MovementBuffer) / MovementSpeedPerAP))
#endregion

#region ActionQueue
var actionQueue: Array[String] = []

func IsPerformingAnyAction() -> bool:
	return actionQueue.size() > 0
#endregion

func onTurnStarted() -> void:
	MovementBuffer = 0.0
	if ActionPointsUsed < ActionPointsMax:
		ActionPointsSaved = 1
	ActionPointsUsed = 0

#region Orders
func IssueOrder_MoveTo(path: PackedVector3Array):
	var lastPoint := path[path.size() - 1]
	parent.navigator.StartMovingTowards(lastPoint)
	var pathCost = ActorNavigator.GetPathMovementCost(path)
	parent.actions.ConsumeMovement(pathCost)
	actionQueue.push_back("dummy value")
	parent.navigator.agent.target_reached.connect(func():
		actionQueue.pop_front(),
	CONNECT_ONE_SHOT)

func IssueOrder_ConfirmCast(skill: Skill, targets: Skill.TargetData):
	var apCost = skill.ActionPointCost
	if ActionPointsAvailable < apCost:
		MessageLog.PrintMessage("Not enough AP")
		return

	for telegraph in TelegraphManager.Instance.telegraphs:
		for validator in telegraph.Definition.Validators:
			var result: Variant = validator.call(telegraph)
			if result is bool and result == false:
				return
			if result is Error:
				MessageLog.PrintErrorObject(result)
				return

	ConsumeActionPoints(apCost)
	skill.PerformCast(targets)

func IssueOrder_Stop():
	if actionQueue.size() == 0:
		return
	actionQueue.pop_front()
	var toRefund = (roundf(parent.navigator.GetRemainingPathLength() * 1000) / 1000)
	RefundMovement(maxf(0.0, toRefund - 0.1))

	parent.navigator.HardStop()

#endregion
