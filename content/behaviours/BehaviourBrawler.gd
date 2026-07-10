extends ActorBehaviourWorldControlled
class_name BehaviourBrawler

const METERS_PER_AP: float = 5.0
const ENGAGEMENT_REFERENCE_METERS: float = 20.0

@export var aggroWeightLowHealth: float = 1.0
@export var aggroWeightHighHealth: float = 2.0
@export var aggroWeightThreat: float = 2.0
@export var aggroWeightProximity: float = 2.0

func evaluateTargetValue(actor: Actor) -> ExplainedThreatValue:
	var effectiveMax = maxi(actor.Stats.HealthMaximum - actor.Stats.HealthHumanityThreshold, 1)
	var effectiveCurrent = clampi(actor.Stats.HealthCurrent - actor.Stats.HealthHumanityThreshold, 0, effectiveMax)
	var lowFraction = 1.0 - float(effectiveCurrent) / float(effectiveMax)
	var highFraction = float(effectiveCurrent) / float(effectiveMax)
	var woundedValue = (aggroWeightLowHealth - 1.0) * lowFraction * float(effectiveMax)
	var unhurtValue = (aggroWeightHighHealth - 1.0) * highFraction * float(effectiveMax)

	var threatValue = actor.Stats.ThreatCurrent * aggroWeightThreat

	var distance = Parent.global_position.distance_to(actor.global_position)
	var apSaved = maxf(0.0, (ENGAGEMENT_REFERENCE_METERS - distance) / METERS_PER_AP)
	var proximityValue = apSaved * aggroWeightProximity

	var result = ExplainedThreatValue.new()

	explainThreatEntry(result, "Wounded", woundedValue)
	explainThreatEntry(result, "Unhurt", unhurtValue)
	explainThreatEntry(result, "%s threat" % ActorUtils.getThreatLevelName(actor.Stats.ThreatCurrent), threatValue)
	explainThreatEntry(result, "Within reach", proximityValue)
	for grudge in getGrudges(actor):
		explainThreatEntry(result, grudge.message, grudge.value)

	return result

func PlanTurnActions() -> Array[TurnAction]:
	if Parent.actions.ActionPointsUsed == 0:
		return [await planMovementAction()]

	return [planCombatAction()]

func planMovementAction() -> TurnAction:
	var adjacentTargetCount = 0
	for rankedTarget in Ranking:
		var target = rankedTarget.Target
		var dist = ActorUtils.flatDistanceBetween(Parent, target) - Parent.Definition.physicalSize
		if dist <= SkillRoundhouseSlash.AttackArea + Parent.physicalSize:
			adjacentTargetCount += 1

	if adjacentTargetCount >= 2:
		return TurnAction.UseSkillOnSelf(SkillRoundhouseSlash)

	var coverMap = await BehaviourUtils.createActorValueMap(Parent)
	if coverMap.points.size() == 0:
		printerr("No points in reach")
		return TurnAction.Skip()

	var bestPointIndex = coverMap.scoredPoints.find_custom(func(point: FloatFieldMap.ScoredPoint):
		return ActorUtils.isPointReachable(Parent, point.point, 1)
	)
	for point in coverMap.scoredPoints:
		print(point.score)
	if bestPointIndex == -1:
		printerr("No points in reach")
		return TurnAction.Skip()
	var currentCover = coverMap.read(Parent.global_position)
	var bestPoint = coverMap.scoredPoints[bestPointIndex].point
	var bestCover = coverMap.read(bestPoint)

	if currentCover >= bestCover and adjacentTargetCount >= 1:
		return TurnAction.UseSkillOnSelf(SkillRoundhouseSlash)
	elif currentCover >= bestCover:
		return TurnAction.UseSkillOnSelf(SkillHunkerDown)

	return TurnAction.MoveTo(bestPoint)

func planCombatAction() -> TurnAction:
	var adjacentTargetCount = 0
	for rankedTarget in Ranking:
		var target = rankedTarget.Target
		var dist = ActorUtils.flatDistanceBetween(Parent, target) - Parent.Definition.physicalSize
		if dist <= Parent.Skills.Get(SkillKnifeSlash).Definition.TargetingMaxRange + Parent.physicalSize:
			adjacentTargetCount += 1

	if adjacentTargetCount == 0:
		return TurnAction.UseSkillOnSelf(SkillStim)

	for rankedTarget in Ranking:
		var target = rankedTarget.Target

		var dist = ActorUtils.flatDistanceBetween(Parent, target) - Parent.Definition.physicalSize
		var knifeRange = Parent.Skills.Get(SkillKnifeSlash).Definition.TargetingMaxRange
		if dist < knifeRange:
			return TurnAction.UseSkillOnActor(SkillKnifeSlash, target)

	return TurnAction.Skip()
