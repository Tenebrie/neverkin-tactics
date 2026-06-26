extends Component
class_name ActorActions

var ActionPointsUsed: int = 0
var ActionPointsMax: int = 3
var ActionPointsSaved: int = 0
var ActionPointsAvailable: int:
	get:
		return ActionPointsMax - ActionPointsUsed + ActionPointsSaved

var MovementBuffer: float = 0.0
var MovementSpeedPerAP: float = 1.0
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
		if ActionPointsAvailable == 0:
			MessageLog.PrintMessage("Out of AP! Press Enter to end turn.")

		if ActionPointsAvailable < 0:
			MovementBuffer = 0.0
			ActionPointsUsed = ActionPointsMax
			return

func GetMovementActionPointCost(value: float) -> int:
	return maxi(0, ceil((value - MovementBuffer) / MovementSpeedPerAP))

func ConsumeActionPoints(value: int):
	while ActionPointsSaved > 0 && value > 0:
		value -= 1
		ActionPointsSaved -= 1
	ActionPointsUsed += value

func _input(event: InputEvent) -> void:
	if (event is InputEventKey && event.keycode == Key.KEY_ENTER && event.is_pressed()):
		MovementBuffer = 0.0
		if ActionPointsUsed < ActionPointsMax:
			ActionPointsSaved = 1
			MessageLog.PrintMessage("Next turn! 1 AP carried over.")
		else:
			MessageLog.PrintMessage("Next turn!")
		ActionPointsUsed = 0
