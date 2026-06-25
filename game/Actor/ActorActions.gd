extends Component
class_name ActorActions

var ActionPointsUsed: float = 0.0
var ActionPointsMax: float = 3.0
var ActionPointsAvailable: float:
	get:
		return ActionPointsMax - ActionPointsUsed

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
		ActionPointsUsed += 1

		if ActionPointsAvailable < 0:
			MovementBuffer = 0.0
			ActionPointsUsed = ActionPointsMax
			return

func GetMovementActionPointCost(value: float) -> float:
	return maxf(0, ceil((value - MovementBuffer) / MovementSpeedPerAP))

func ConsumeActionPoints(value: float):
	ActionPointsUsed += value

func _input(event: InputEvent) -> void:
	if (event is InputEventKey && event.keycode == Key.KEY_ENTER && event.is_pressed()):
		MovementBuffer = 0.0
		ActionPointsUsed = 0.0
		print("Next turn")
