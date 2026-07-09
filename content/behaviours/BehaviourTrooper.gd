extends ActorBehaviourWorldControlled
class_name BehaviourTrooper

const METERS_PER_AP: float = 5.0
const ENGAGEMENT_REFERENCE_METERS: float = 20.0

@export var aggroWeightLowHealth: float = 2.0
@export var aggroWeightHighHealth: float = 1.0
@export var aggroWeightThreat: float = 2.0
@export var aggroWeightProximity: float = 1.0

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
	var coverMap = await BehaviourUtils.createActorValueMap(Parent)
	if coverMap.points.size() == 0:
		printerr("No points in reach")
		return TurnAction.Skip()

	var bestPointIndex = coverMap.scoredPoints.find_custom(func(point: FloatFieldMap.ScoredPoint):
		return ActorUtils.isPointReachable(Parent, point.point, 1)
	)
	if bestPointIndex == -1:
		printerr("No points in reach")
		return TurnAction.Skip()
	var bestPoint = coverMap.scoredPoints[bestPointIndex].point
	var currentCover = coverMap.read(Parent.global_position)
	var bestCover = coverMap.read(bestPoint)

	if bestCover <= currentCover:
		return TurnAction.UseSkillOnSelf(SkillHunkerDown)

	return TurnAction.MoveTo(bestPoint)

func planCombatAction() -> TurnAction:
	for rankedTarget in Ranking:
		var target = rankedTarget.Target
		if target.isDead:
			continue

		var dist = ActorUtils.flatDistanceBetween(Parent, target) - Parent.Definition.PhysicalSize
		var pistolRange = Parent.Skills.Get(SkillPistolShot).Definition.TargetingMaxRange
		var grenadeRange = Parent.Skills.Get(SkillFragGrenade).Definition.TargetingMaxRange
		if dist < pistolRange and ActorUtils.hasLineOfSight(Parent, target):
			return TurnAction.UseSkillOnActor(SkillPistolShot, target)
		elif dist < grenadeRange:
			return TurnAction.UseSkillOnActor(SkillFragGrenade, target)

	return TurnAction.Skip()
