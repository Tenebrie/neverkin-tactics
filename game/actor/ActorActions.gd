extends Component
class_name ActorActions

signal ActionPointsChanged(current: int)
signal MovementPointsChanged(current: float)

var ActionPointsUsed: int = 0

var ActionPointsMax: int:
	get: return Parent.Definition.ActionPointsMax + ActionPointsSavedMax
var ActionPointsSavedMax: int = 0

var ActionPointsAvailable: int:
	get:
		return ActionPointsMax - ActionPointsUsed

var _actionPointsThreatenedFromSkill: int = 0
var ActionPointsThreatened: int:
	get:
		return _actionPointsThreatenedFromSkill

func ConsumeActionPoints(value: int):
	ActionPointsUsed += value
	MovementBuffer = 0.0
	ActionPointsChanged.emit(ActionPointsAvailable)
	SignalBus.ActionPointsConsumedPermanently.emit(Parent, value)

func ConsumeActionPointsRefundable(value: int):
	ActionPointsUsed += value
	ActionPointsChanged.emit(ActionPointsAvailable)

func RefundActionPoints(value: int):
	while ActionPointsUsed > 0 && value > 0:
		value -= 1
		ActionPointsUsed -= 1
	ActionPointsChanged.emit(ActionPointsAvailable)

#region Movement
var MovementSpeedPerAP: float:
	get:
		return Parent.Definition.MovementSpeedPerActionPoint
var MovementBuffer: float = 0.0:
	set(v):
		MovementBuffer = v
		MovementPointsChanged.emit(v)
var MovementAvailable: float:
	get:
		return MovementBuffer + MovementSpeedPerAP * ActionPointsAvailable

func _parentReady() -> void:
	Parent.Skills.SelectedSkillChanged.connect(func(skill):
		if skill:
			_actionPointsThreatenedFromSkill = skill.Definition.ActionPointCost
		else:
			_actionPointsThreatenedFromSkill = 0
	)
	TurnManager.Instance.FactionTurnEnded.connect(onTurnEnded)

func ConsumeMovement(value: float):
	for i in 50:
		if value <= MovementBuffer:
			MovementBuffer -= value
			return
		MovementBuffer += MovementSpeedPerAP
		ConsumeActionPointsRefundable(1)

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
var ActionQueue: ActorActionQueue = ActorActionQueue.new()

func IsPerformingAnyAction() -> bool:
	return ActionQueue.Busy()
#endregion

func onTurnEnded(faction: Actor.Alliance) -> void:
	if faction != Parent.Definition.Alliance:
		return
	MovementBuffer = 0.0
	if ActionPointsUsed < ActionPointsMax:
		ActionPointsSavedMax = 1
	else:
		ActionPointsSavedMax = 0
	ActionPointsUsed = 0

#region Orders
func IssueOrder_MoveThroughPath(path: PackedVector3Array):
	var lastPoint := path[path.size() - 1]
	Parent.navigator.StartMovingTowards(lastPoint)
	var pathCost = ActorNavigator.GetPathMovementCost(path)
	Parent.actions.ConsumeMovement(pathCost)
	ActionQueue.Push("dummy value")
	Parent.navigator.agent.target_reached.connect(func():
		ActionQueue.ConsumeFirst(),
	CONNECT_ONE_SHOT)

func IssueOrder_ConfirmCast(skill: Skill, targets: Skill.TargetData):
	var apCost = skill.ActionPointCost
	if ActionPointsAvailable < apCost:
		MessageLog.PrintMessage("Not enough AP")
		return

	for telegraph in Parent.Telegraphs.telegraphs:
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
	if ActionQueue.Empty():
		return
	ActionQueue.Clear()
	var toRefund = (roundf(Parent.navigator.GetRemainingPathLength() * 1000) / 1000)
	RefundMovement(maxf(0.0, toRefund - 0.1))

	Parent.navigator.HardStop()

#endregion

class ActorActionQueue:
	signal StepCompleted
	signal QueueEmptied

	var queue: Array[String] = []

	func Empty() -> bool:
		return queue.size() == 0

	func Busy() -> bool:
		return queue.size() > 0

	func Clear() -> void:
		queue.pop_front()

	func Push(action: String) -> void:
		queue.push_back(action)

	func ConsumeFirst() -> void:
		queue.pop_front()
		StepCompleted.emit()
		if queue.size() == 0:
			QueueEmptied.emit()

static var SignalBus: SignalBusImplementation = SignalBusImplementation.new()
class SignalBusImplementation:
	signal ActionPointsConsumedPermanently(actor: Actor, value: int)
