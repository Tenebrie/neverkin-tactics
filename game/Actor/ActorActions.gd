extends Component
class_name ActorActions

@export var ActionPointsUsed: int = 0
@export var ActionPointsMax: int = 3
var ActionPointsSaved: int = 0
var ActionPointsAvailable: int:
	get:
		return ActionPointsMax - ActionPointsUsed + ActionPointsSaved

func ConsumeActionPoints(value: int):
	while ActionPointsSaved > 0 && value > 0:
		value -= 1
		ActionPointsSaved -= 1
	ActionPointsUsed += value

func RefundActionPoints(value: int):
	while ActionPointsUsed > 0 && value > 0:
		value -= 1
		ActionPointsUsed -= 1
	ActionPointsSaved += value

#region Movement
@export var MovementSpeedPerAP: float = 1.0
var MovementBuffer: float = 0.0
var MovementAvailable: float:
	get:
		return MovementBuffer + MovementSpeedPerAP * ActionPointsAvailable

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

func _input(event: InputEvent) -> void:
	if parent is not Player:
		return

	if (event is InputEventKey && event.keycode == Key.KEY_ENTER && event.is_pressed()):
		MovementBuffer = 0.0
		if ActionPointsUsed < ActionPointsMax:
			ActionPointsSaved = 1
			MessageLog.PrintMessage("Next turn! 1 AP carried over.")
		else:
			MessageLog.PrintMessage("Next turn!")
		ActionPointsUsed = 0

#region Orders
func IssueOrder_MoveTo(path: PackedVector3Array):
	var lastPoint := path[path.size() - 1]
	parent.navigator.StartMovingTowards(lastPoint)
	var pathCost = ActorNavigator.GetPathMovementCost(path)
	parent.actions.ConsumeMovement(pathCost)
	actionQueue.push_back("value")
	parent.navigator.agent.target_reached.connect(func():
		actionQueue.pop_front(),
	CONNECT_ONE_SHOT)

func IssueOrder_Stop():
	if actionQueue.size() == 0:
		return
	actionQueue.pop_front()
	var toRefund = (roundf(parent.navigator.GetRemainingPathLength() * 1000) / 1000)
	RefundMovement(maxf(0.0, toRefund - 0.1))

	parent.navigator.HardStop()

#endregion
