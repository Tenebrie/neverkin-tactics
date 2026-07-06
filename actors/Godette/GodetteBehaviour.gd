extends ActorBehaviourWorldControlled

const METERS_PER_AP: float = 5.0
const ENGAGEMENT_REFERENCE_METERS: float = 20.0
const HIGHLIGHT_THRESHOLD: float = 1.0

@export var WEIGHT_LOW_HEALTH: float = 2.0
@export var WEIGHT_HIGH_HEALTH: float = 1.0
@export var WEIGHT_THREAT: float = 2.0
@export var WEIGHT_PROXIMITY: float = 1.0
@export var WEIGHT_GRUDGE: float = 1.0

var Grudges: Dictionary[Actor, float] = {}

func _parentReady() -> void:
	super._parentReady()
	Parent.Stats.DamageTaken.connect(func(damage: DamageInstance):
		RecordGrudge(damage.SourceActor, damage.Value)
	)

func RecordGrudge(against: Actor, swings: float) -> void:
	if against == null:
		return
	Grudges[against] = Grudges.get(against, 0.0) + swings

func ForgiveGrudge(against: Actor) -> void:
	Grudges.erase(against)

func evaluateTargetValue(actor: Actor) -> ExplainedThreatValue:
	var effectiveMax = maxi(actor.Stats.HealthMaximum - actor.Stats.HealthHumanityThreshold, 1)
	var effectiveCurrent = clampi(actor.Stats.HealthCurrent - actor.Stats.HealthHumanityThreshold, 0, effectiveMax)
	var lowFraction = 1.0 - float(effectiveCurrent) / float(effectiveMax)
	var highFraction = float(effectiveCurrent) / float(effectiveMax)
	var woundedValue = (WEIGHT_LOW_HEALTH - 1.0) * lowFraction * float(effectiveMax)
	var unhurtValue = (WEIGHT_HIGH_HEALTH - 1.0) * highFraction * float(effectiveMax)

	var threatValue = actor.Stats.ThreatCurrent * WEIGHT_THREAT

	var distance = Parent.global_position.distance_to(actor.global_position)
	var apSaved = maxf(0.0, (ENGAGEMENT_REFERENCE_METERS - distance) / METERS_PER_AP)
	var proximityValue = apSaved * WEIGHT_PROXIMITY

	var grudgeValue = Grudges.get(actor, 0.0) * WEIGHT_GRUDGE

	var result = ExplainedThreatValue.new()

	addHighlight(result, "Wounded", woundedValue)
	addHighlight(result, "Unhurt", unhurtValue)
	addHighlight(result, "%s threat" % ActorUtils.GetThreatLevelName(actor.Stats.ThreatCurrent), threatValue)
	addHighlight(result, "Within reach", proximityValue)
	addHighlight(result, "Attacked me!", grudgeValue)

	return result

func addHighlight(result: ExplainedThreatValue, label: String, value: float) -> void:
	result.Total += floori(value)
	result.TotalPrecise += value
	if value >= HIGHLIGHT_THRESHOLD:
		result.Highlights[label] = value

func PlanTurnActions() -> Array[TurnAction]:
	if Parent.actions.ActionPointsUsed == 0:
		return [planMovementAction()]

	return [planCombatAction()]

func planMovementAction() -> TurnAction:
	var coverMap = BehaviourUtils.CreateActorCoverMap(Parent)
	if coverMap.Points.size() == 0:
		printerr("No cover points in the map")
		return TurnAction.Skip()

	var points = coverMap.Points.filter(func(point): return ActorUtils.IsPointReachable(Parent, point, 1))
	points.sort_custom(func(a, b):
		return coverMap.Read(a) > coverMap.Read(b)
	)
	var currentCover = coverMap.Read(Parent.global_position)
	var bestCover = coverMap.Read(points[0])

	if bestCover < currentCover:
		print("Staying: ", currentCover, " / ", bestCover)
		return TurnAction.UseSkillOnSelf(SkillHunkerDown)

	print("Moving: ", currentCover, " / ", bestCover)
	return TurnAction.MoveTo(points[0])

func planCombatAction() -> TurnAction:
	var dist = ActorUtils.FlatDistanceBetween(Parent, FocusedTarget) - Parent.Definition.PhysicalSize
	var pistolRange = Parent.Skills.Get(SkillPistolShot).Definition.TargetingMaxRange
	var grenadeRange = Parent.Skills.Get(SkillFragGrenade).Definition.TargetingMaxRange
	if dist < pistolRange and ActorUtils.HasLineOfSight(Parent, FocusedTarget):
		return TurnAction.UseSkillOnActor(SkillPistolShot, FocusedTarget)
	elif dist < grenadeRange:
		return TurnAction.UseSkillOnActor(SkillFragGrenade, FocusedTarget)
	return TurnAction.Skip()
