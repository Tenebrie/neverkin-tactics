@abstract extends ActorBehaviour
class_name ActorBehaviourWorldControlled

## When an enemy's threat level exceedes the fear threshold, this enemy becomes the focused target
@export var EnableFear = true
@export var FearThreshold = Actor.ThreatLevel.Deadly

var FocusedTarget: Actor = null
var FocusedTargetTotal: float = 0.0
var FocusedTargetReasons: Dictionary[String, float] = {}

var Ranking: Array[RankedTarget] = []

class ExplainedThreatValue:
	var Total: int = 0
	var TotalPrecise: float = 0.0
	var Highlights: Dictionary[String, float] = {}

class RankedTarget:
	var Target: Actor
	var Value: ExplainedThreatValue

func _ready() -> void:
	var inputProvider = ActorInputProvider.new()
	await get_tree().process_frame
	Parent.add_child(inputProvider)
	Parent.InputProvider = inputProvider

func _process(_delta: float) -> void:
	Ranking = computeRanking()
	if Ranking.is_empty():
		FocusedTarget = null
		FocusedTargetTotal = 0.0
		FocusedTargetReasons = {}
		return
	FocusedTarget = Ranking[0].Target
	FocusedTargetTotal = Ranking[0].Value.Total
	FocusedTargetReasons = Ranking[0].Value.Highlights

func computeRanking() -> Array[RankedTarget]:
	var result: Array[RankedTarget] = []
	var targets = Actor.Repository.All.List.filter(func(actor):
		return ActorUtils.IsHostileTo(actor, Parent)
	)
	if targets.size() == 0:
		return result

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

	for actor in targets:
		var ranked = RankedTarget.new()
		ranked.Target = actor
		ranked.Value = targetToThreat[actor] if fearThresholdReached else targetToReason[actor]
		result.push_back(ranked)
	return result

func evaluateTargetThreat(actor: Actor) -> ExplainedThreatValue:
	var value = ExplainedThreatValue.new()
	value.Total = actor.Stats.ThreatCurrent
	value.Highlights["Scary!"] = actor.Stats.ThreatCurrent
	return value

@abstract func evaluateTargetValue(actor: Actor) -> ExplainedThreatValue
