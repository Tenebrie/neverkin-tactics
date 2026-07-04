@abstract extends ActorBehaviour
class_name ActorBehaviourWorldControlled

## When an enemy's threat level exceedes the fear threshold, this enemy becomes the focused target
@export var EnableFear = true
@export var FearThreshold = Actor.ThreatLevel.Deadly

var FocusedTarget: Actor = null
var FocusedTargetReasons: Dictionary[String, float] = {}

class ExplainedThreatValue:
	var Total: float = 0.0
	var Highlights: Dictionary[String, float] = {}

func _ready() -> void:
	var inputProvider = ActorInputProvider.new()
	await get_tree().process_frame
	Parent.add_child(inputProvider)
	Parent.InputProvider = inputProvider

func UpdateFocusedTarget() -> void:
	var targets = Actor.Repository.All.List.filter(func(actor):
		return ActorUtils.IsHostileTo(actor, Parent)
	)
	if targets.size() == 0:
		FocusedTarget = null
		return

	var targetToThreat: Dictionary[Actor, ExplainedThreatValue]
	var targetToReason: Dictionary[Actor, ExplainedThreatValue]
	for actor in targets:
		targetToThreat[actor] = evaluateTargetThreat(actor)
		targetToReason[actor] = evaluateTargetValue(actor)

	var fearThresholdReached = targets.any(func(actor):
		return targetToThreat[actor].Total >= FearThreshold
	)

	var parentPosition = Parent.global_position
	var scoreOf = func(actor):
		return targetToThreat[actor].Total if fearThresholdReached else targetToReason[actor].Total

	targets.sort_custom(func(a, b):
		if scoreOf.call(a) != scoreOf.call(b):
			return scoreOf.call(a) > scoreOf.call(b)
		return a.global_position.distance_squared_to(parentPosition) < b.global_position.distance_squared_to(parentPosition)
	)
	FocusedTarget = targets[0]
	FocusedTargetReasons = targetToThreat[FocusedTarget].Highlights if fearThresholdReached else targetToReason[FocusedTarget].Highlights

func GetFocusedTargetReasonsImmediate() -> ExplainedThreatValue:
	if not FocusedTarget:
		return

	var targetToThreat: Dictionary[Actor, ExplainedThreatValue]
	var targetToReason: Dictionary[Actor, ExplainedThreatValue]
	targetToThreat[FocusedTarget] = evaluateTargetThreat(FocusedTarget)
	targetToReason[FocusedTarget] = evaluateTargetValue(FocusedTarget)

	var fearThresholdReached = targetToThreat[FocusedTarget].Total >= FearThreshold

	return targetToThreat[FocusedTarget] if fearThresholdReached else targetToReason[FocusedTarget]

func evaluateTargetThreat(actor: Actor) -> ExplainedThreatValue:
	var value = ExplainedThreatValue.new()
	value.Total = actor.Stats.ThreatCurrent
	value.Highlights["Scary!"] = actor.Stats.ThreatCurrent
	return value

@abstract func evaluateTargetValue(actor: Actor) -> ExplainedThreatValue
