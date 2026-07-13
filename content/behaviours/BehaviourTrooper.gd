extends ActorBehaviourWorldControlled
class_name BehaviourTrooper

const METERS_PER_AP: float = 5.0
const ENGAGEMENT_REFERENCE_METERS: float = 20.0

@export var aggroWeightLowHealth: float = 2.0
@export var aggroWeightHighHealth: float = 1.0
@export var aggroWeightThreat: float = 2.0
@export var aggroWeightProximity: float = 1.0

func evaluateTargetValue(actor: Actor) -> ExplainedThreatValue:
	var effectiveMax = maxi(actor.stats.healthMaximum - actor.stats.healthHumanityThreshold, 1)
	var effectiveCurrent = clampi(actor.stats.healthCurrent - actor.stats.healthHumanityThreshold, 0, effectiveMax)
	var lowFraction = 1.0 - float(effectiveCurrent) / float(effectiveMax)
	var highFraction = float(effectiveCurrent) / float(effectiveMax)
	var woundedValue = (aggroWeightLowHealth - 1.0) * lowFraction * float(effectiveMax)
	var unhurtValue = (aggroWeightHighHealth - 1.0) * highFraction * float(effectiveMax)

	var threatValue = actor.stats.threatCurrent * aggroWeightThreat

	var distance = parent.global_position.distance_to(actor.global_position)
	var apSaved = maxf(0.0, (ENGAGEMENT_REFERENCE_METERS - distance) / METERS_PER_AP)
	var proximityValue = apSaved * aggroWeightProximity

	var result = ExplainedThreatValue.new()

	explainThreatEntry(result, "Wounded", woundedValue)
	explainThreatEntry(result, "Unhurt", unhurtValue)
	explainThreatEntry(result, "%s threat" % ActorUtils.getThreatLevelName(actor.stats.threatCurrent), threatValue)
	explainThreatEntry(result, "Within reach", proximityValue)
	for grudge in getGrudges(actor):
		explainThreatEntry(result, grudge.message, grudge.value)

	return result

func PlanTurnActions() -> Array[TurnAction]:
	if parent.actions.ActionPointsUsed == 0:
		return [await planMovementAction()]

	return [planCombatAction()]

func planMovementAction() -> TurnAction:
	var coverMap = await BehaviourUtils.createActorValueMap(parent)
	if coverMap.points.size() == 0:
		printerr("No points in reach")
		return TurnAction.Skip()

	var bestPointIndex = coverMap.scoredPoints.find_custom(func(point: FloatFieldMap.ScoredPoint):
		return ActorUtils.isPointReachable(parent, point.point, 1)
	)
	if bestPointIndex == -1:
		printerr("No points in reach")
		return TurnAction.Skip()
	var bestPoint = coverMap.scoredPoints[bestPointIndex].point
	var currentCover = coverMap.read(parent.global_position)
	var bestCover = coverMap.read(bestPoint)

	if bestCover <= currentCover:
		return TurnAction.UseSkillOnSelf(SkillHunkerDown)

	return TurnAction.MoveTo(bestPoint)

func planCombatAction() -> TurnAction:
	for rankedTarget in Ranking:
		var target = rankedTarget.Target
		if target.isDead:
			continue

		var dist = ActorUtils.flatDistanceBetween(parent, target) - parent.definition.physicalSize
		var pistolRange = parent.Skills.Get(SkillPistolShot).definition.TargetingMaxRange
		var grenadeRange = parent.Skills.Get(SkillFragGrenade).definition.TargetingMaxRange
		if dist < pistolRange and ActorUtils.hasLineOfSight(parent, target):
			return TurnAction.UseSkillOnActor(SkillPistolShot, target)
		elif dist < grenadeRange:
			return TurnAction.UseSkillOnActor(SkillFragGrenade, target)

	return TurnAction.Skip()
