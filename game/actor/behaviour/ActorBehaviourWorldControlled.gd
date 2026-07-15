@abstract extends ActorBehaviour
class_name ActorBehaviourWorldControlled

## How many turns of movement this actor is willing to spend to reach a focus target
@export var EngagementHorizonTurns: int = 2

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
## How much does this actor try to avoid going into enemy melee range
@export var WeightAvoidMeleeRange: float = 0.0
## How much does this actor try to break line of sight to threats
@export var WeightAvoidLineOfSight: float = 1.0
# How reluctant is this actor to move from their current position
@export var WeightDistanceToMove: float = 1.0
# How much is this actor attracted towards allies
@export var WeightProximityToAllies: float = 0.0
# Range at which proximity influence decays to 0
@export var WeightProximityToAlliesFalloffMeters: float = 10.0
# How much is this actor attracted towards enemies
@export var WeightProximityToEnemies: float = 1.0
# Range at which proximity influence decays to 0
@export var WeightProximityToEnemiesFalloffMeters: float = 10.0
# How much is this actor unhappy about being far from the fight
@export var WeightOutOfFight: float = 1.0
# Distance from the fight at which the actor starts to be penalized
@export var WeightOutOfFightMinDistance: float = 10.0
# How offended is this actor about being targeted by enemy skills
@export var WeightGrudges: float = 1.0

var FocusedTarget: Actor = null
var FocusedTargetTotal: float = 0.0
var FocusedTargetReasons: Dictionary[String, float] = {}

var Ranking: Array[RankedTarget] = []
var Grudges: Dictionary[Array, SkillGrudge] = {}

class ExplainedThreatValue:
	var Total: int = 0
	var TotalPrecise: float = 0.0
	var Highlights: Dictionary[String, float] = {}

class SkillGrudge:
	var value: float
	var message: String
	var sourceActor: Actor

class RankedTarget:
	var Target: Actor
	var Value: ExplainedThreatValue
	var Tier: int
	var Engageable: bool

func _ready() -> void:
	updateRanking()

func _parentReady() -> void:
	super._parentReady()
	parent.stats.damageTaken.connect(func(damage: DamageInstance):
		RecordGrudge(damage, damage.sourceActor)
	)
	ActorActions.SignalBus.ActionPointsConsumedPermanently.connect(func(actor: Actor, _value: int):
		if actor.faction != parent.faction:
			updateRanking()
	)
	TurnManager.Instance.TurnChanged.connect(updateRanking)

func getGrudges(actor: Actor) -> Array[SkillGrudge]:
	if WeightGrudges == 0:
		return []

	var out: Array[SkillGrudge]
	for grudge: SkillGrudge in Grudges.values():
		if grudge.sourceActor == actor and grudge.value >= 1.0:
			out.push_back(grudge)
	return out

func RecordGrudge(damage: DamageInstance, grudgeTarget: Actor) -> void:
	if not damage.sourceActor or not damage.sourceSkill:
		return

	var grudgeString = damage.sourceSkill.definition.GrudgeString
	if not grudgeString:
		grudgeString = "Attacked me!"
	var message = damage.sourceActor.pronouns.evaluate(grudgeString)
	var key = [grudgeTarget, damage.sourceSkill.definition]
	if Grudges.has(key):
		Grudges[key].value += damage.Value
		return

	var grudge = SkillGrudge.new()
	grudge.value = damage.Value
	grudge.message = message
	grudge.sourceActor = grudgeTarget
	Grudges[key] = grudge

const HIGHLIGHT_THRESHOLD: float = 1.0
func explainThreatEntry(result: ExplainedThreatValue, label: String, value: float) -> void:
	result.Total += floori(value)
	result.TotalPrecise += value
	if value >= HIGHLIGHT_THRESHOLD:
		result.Highlights[label] = value

const FOCUS_STICKINESS_FRACTION: float = 0.3
const FOCUS_STICKINESS_MINIMUM: float = 2.0

func updateRanking():
	Ranking = _computeRanking()
	if Ranking.is_empty():
		FocusedTarget = null
		FocusedTargetTotal = 0.0
		FocusedTargetReasons = {}
		return

	_applyFocusStickiness()
	FocusedTarget = Ranking[0].Target
	FocusedTargetTotal = Ranking[0].Value.Total
	FocusedTargetReasons = Ranking[0].Value.Highlights

func _applyFocusStickiness() -> void:
	if not is_instance_valid(FocusedTarget) or FocusedTarget.isDead:
		return
	var previousIndex = Ranking.find_custom(func(rank: RankedTarget): return rank.Target == FocusedTarget)
	if previousIndex <= 0:
		return
	var previous = Ranking[previousIndex]
	var top = Ranking[0]
	if not previous.Engageable or previous.Tier != top.Tier:
		return
	var switchThreshold = previous.Value.TotalPrecise + maxf(previous.Value.TotalPrecise * FOCUS_STICKINESS_FRACTION, FOCUS_STICKINESS_MINIMUM)
	if top.Value.TotalPrecise >= switchThreshold:
		return
	Ranking.remove_at(previousIndex)
	Ranking.push_front(previous)

func RefocusOn(target: Actor, reason: String) -> void:
	if FocusedTarget == target:
		return
	FocusedTarget = target
	var index = Ranking.find_custom(func(rank: RankedTarget): return rank.Target == target)
	FocusedTargetTotal = Ranking[index].Value.Total if index != -1 else 0.0
	FocusedTargetReasons = { reason: maxf(FocusedTargetTotal, 1.0) }
	MessageLog.PrintActorMessage(reason, parent)

func _computeRanking() -> Array[RankedTarget]:
	var result: Array[RankedTarget] = []
	var targets = Actor.Repository.Alive.List.filter(func(actor):
		return ActorUtils.isHostileTo(actor, parent) and actor.isAlive
	)
	if targets.size() == 0:
		return result

	var attackRange = 0.0
	if parent and parent.Skills:
		attackRange = _maxAttackRange()
	for actor in targets:
		var ranked = RankedTarget.new()
		ranked.Target = actor
		ranked.Value = evaluateTargetValue(actor)
		ranked.Tier = threatTierOf(actor)
		ranked.Engageable = isEngageable(actor, attackRange)
		result.push_back(ranked)

	var parentPosition = parent.global_position
	result.sort_custom(func(a: RankedTarget, b: RankedTarget):
		if a.Engageable != b.Engageable:
			return a.Engageable
		if a.Tier != b.Tier:
			return a.Tier > b.Tier
		if a.Value.TotalPrecise != b.Value.TotalPrecise:
			return a.Value.TotalPrecise > b.Value.TotalPrecise
		return a.Target.global_position.distance_squared_to(parentPosition) < b.Target.global_position.distance_squared_to(parentPosition)
	)
	return result

func threatTierOf(actor: Actor) -> int:
	return maxi(floori(actor.stats.threatCurrent), 0)

func isEngageable(target: Actor, attackRange: float) -> bool:
	if attackRange <= 0.0:
		return true
	if ActorUtils.flatDistanceBetweenActors(parent, target) <= attackRange:
		return true
	var mapRid = parent.navigator.agent.get_navigation_map()
	var path = NavigationUtils.getPath(mapRid, parent.global_position, target.global_position)
	if path.is_empty():
		return false
	var movementBudget = parent.movementSpeedPerAction * parent.actions.ActionPointsMax * EngagementHorizonTurns
	if NavigationUtils.getPathLength(path) > movementBudget + attackRange:
		return false
	var pathEnd = Vector3(path[-1].x, 0.0, path[-1].z)
	var endGap = pathEnd.distance_to(ActorUtils.flatPositionOf(target)) - parent.physicalSize - target.physicalSize
	return endGap <= attackRange

func _maxAttackRange() -> float:
	var out = 0.0
	for skill in BehaviourUtils.gatherAttackSkills(parent):
		out = maxf(out, skill.TargetingMaxRange)
	return out

@abstract func evaluateTargetValue(actor: Actor) -> ExplainedThreatValue
@abstract func PlanTurnActions() -> Array[TurnAction]

func PlanTurnActionsWithCrowdControl() -> Array[TurnAction]:
	if parent.buffs.Has(SkillGriffonGripBuff):
		return [TurnAction.UseSkillOnSelf(SkillBreakFree)]

	return await PlanTurnActions()
