extends ActorBehaviourWorldControlled
class_name BehaviourTrooper

const METERS_PER_AP: float = 5.0
const ENGAGEMENT_REFERENCE_METERS: float = 20.0

@export var aggroWeightLowHealth: float = 2.0
@export var aggroWeightHighHealth: float = 1.0
@export var aggroWeightThreat: float = 2.0
@export var aggroWeightProximity: float = 1.0
## How much combined map score this actor is willing to give up for a shot at the focus target
@export var focusCommitmentMargin: float = 3.0

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
	var maps = await BehaviourUtils.createActorValueMaps(parent)
	var valueMap = maps.combined
	if valueMap.points.size() == 0:
		printerr("No points in reach")
		return TurnAction.Skip()

	var bestOverallIndex = valueMap.scoredPoints.find_custom(func(point: FloatFieldMap.ScoredPoint):
		return ActorUtils.isPointReachable(parent, point.point, 1)
	)
	if bestOverallIndex == -1:
		printerr("No points in reach")
		return TurnAction.Skip()
	var bestOverall = valueMap.scoredPoints[bestOverallIndex]
	var currentScore = valueMap.read(parent.global_position)

	if not FocusedTarget:
		if bestOverall.score <= currentScore:
			return TurnAction.UseSkillOnSelf(SkillHunkerDown)
		return TurnAction.MoveTo(bestOverall.point)

	var bestShotIndex = valueMap.scoredPoints.find_custom(func(point: FloatFieldMap.ScoredPoint):
		return maps.focusShot.read(point.point) > 0.0 and ActorUtils.isPointReachable(parent, point.point, 1)
	)

	if bestShotIndex == -1 or bestOverall.score - valueMap.scoredPoints[bestShotIndex].score > focusCommitmentMargin:
		var pistolRange = parent.Skills.Get(SkillPistolShot).definition.TargetingMaxRange
		var approaching = ActorUtils.flatDistanceBetweenActors(parent, FocusedTarget) > pistolRange + parent.movementSpeedPerAction
		if not approaching:
			MessageLog.PrintActorMessage("Pinned down!", parent)
		if bestOverall.score <= currentScore:
			return TurnAction.UseSkillOnSelf(SkillHunkerDown)
		return TurnAction.MoveTo(bestOverall.point)

	var bestShot = valueMap.scoredPoints[bestShotIndex]
	var currentHasShot = maps.focusShot.read(parent.global_position) > 0.0
	if currentHasShot and bestShot.score <= currentScore:
		return planCombatAction()
	return TurnAction.MoveTo(bestShot.point)

func tryAttack(target: Actor) -> TurnAction:
	if not target or target.isDead:
		return null

	var dist = ActorUtils.flatDistanceBetweenActors(parent, target)
	var pistolRange = parent.Skills.Get(SkillPistolShot).definition.TargetingMaxRange
	var grenadeRange = parent.Skills.Get(SkillFragGrenade).definition.TargetingMaxRange
	if dist < pistolRange and ActorUtils.hasLineOfSight(parent, target):
		return TurnAction.UseSkillOnActor(SkillPistolShot, target)
	elif dist < grenadeRange:
		return TurnAction.UseSkillOnActor(SkillFragGrenade, target)
	return null

func planCombatAction() -> TurnAction:
	var focusAttack = tryAttack(FocusedTarget)
	if focusAttack:
		return focusAttack

	for rankedTarget in Ranking:
		if rankedTarget.Target == FocusedTarget:
			continue
		var fallbackAttack = tryAttack(rankedTarget.Target)
		if fallbackAttack:
			RefocusOn(rankedTarget.Target, "Target of opportunity!")
			return fallbackAttack

	return TurnAction.Skip()
