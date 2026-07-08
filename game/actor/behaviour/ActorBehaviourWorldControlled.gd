@abstract extends ActorBehaviour
class_name ActorBehaviourWorldControlled

## When an enemy's threat level exceedes the fear threshold, this enemy becomes the focused target
@export var EnableFear = true
@export var FearThreshold = Actor.ThreatLevel.Deadly

## Ideal distance from enemies. 0 disables preferred-range scoring. Reward falls off symmetrically on either side.
@export var PreferredRange: float = 0.0
## Sigma of the bell curve around PreferredRange. Larger = more forgiving.
@export var PreferredRangeTolerance: float = 3.0

## Per-actor multipliers on top of the base weights in BehaviourUtils. 1.0 = default, 0 = disabled.
@export_group("Behaviour Weights", "Weight")
## How valuable is cover for this actor
@export var WeightCover: float = 1.0
## How badly this actor wants to be able to attack
@export var WeightHasShot: float = 1.0
## How much does this actor try to break line of sight to threats
@export var WeightAvoidLineOfSight: float = 1.0
# How reluctant is this actor to move from their current position
@export var WeightDistanceToMove: float = 1.0
# How much is this actor attracted towards allies
@export var WeightProximityToAllies: float = 1.0
# Range at which proximity influence decays to 0
@export var WeightProximityToAlliesFalloffMeters: float = 10.0
# How much is this actor attracted towards enemies
@export var WeightProximityToEnemies: float = 1.0
# Range at which proximity influence decays to 0
@export var WeightProximityToEnemiesFalloffMeters: float = 10.0

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
	if TurnManager.Instance.CurrentFaction != Actor.Faction.Player:
		return
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
		return ActorUtils.isHostileTo(actor, Parent)
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
@abstract func PlanTurnActions() -> Array[TurnAction]
