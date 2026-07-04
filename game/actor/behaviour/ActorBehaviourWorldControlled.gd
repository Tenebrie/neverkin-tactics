@abstract extends ActorBehaviour
class_name ActorBehaviourWorldControlled

## When an enemy's threat level exceedes the fear threshold, this enemy becomes the focused target
@export var EnableFear = true
@export var FearThreshold = Actor.ThreatLevel.Deadly

var FocusedTarget

func _ready() -> void:
	var inputProvider = ActorInputProvider.new()
	await get_tree().process_frame
	Parent.add_child(inputProvider)
	Parent.InputProvider = inputProvider

func UpdateFocusedTarget() -> void:
	var targets = Actor.Repository.All.List.filter(func(actor):
		return actor.Definition.Alliance != Actor.Alliance.Player
	)
	if targets.size() == 0:
		FocusedTarget = null
		return

	var targetToThreat: Dictionary[Actor, float]
	var targetToValue: Dictionary[Actor, float]
	for actor in targets:
		targetToThreat[actor] = evaluateTargetThreat(actor)
		targetToValue[actor] = evaluateTargetValue(actor)

	var fearThresholdReached = targets.any(func(actor):
		return targetToThreat[actor] >= FearThreshold
	)

	var parentPosition = Parent.global_position
	var scoreOf: Dictionary[Actor, float] = targetToThreat if fearThresholdReached else targetToValue

	targets.sort_custom(func(a, b):
		if scoreOf[a] != scoreOf[b]:
			return scoreOf[a] > scoreOf[b]
		return a.global_position.distance_squared_to(parentPosition) < b.global_position.distance_squared_to(parentPosition)
	)
	FocusedTarget = targets[0]

func evaluateTargetThreat(actor: Actor) -> float:
	return actor.Stats.ThreatCurrent

@abstract func evaluateTargetValue(actor: Actor) -> float
