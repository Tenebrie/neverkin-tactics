extends ActorBehaviourWorldControlled

const METERS_PER_AP: float = 3.0
const ENGAGEMENT_REFERENCE_METERS: float = 100.0

@export var WEIGHT_LOW_HEALTH: float = 3.0
@export var WEIGHT_HIGH_HEALTH: float = 1.0
@export var WEIGHT_THREAT: float = 0
@export var WEIGHT_PROXIMITY: float = 0.2
@export var WEIGHT_GRUDGE: float = 1.0

func _parentReady() -> void:
	super._parentReady()
	parent.Stats.DamageTaken.connect(func(damage: DamageInstance):
		RecordGrudge(damage, damage.sourceActor)
	)

func evaluateTargetValue(actor: Actor) -> ExplainedThreatValue:
	var effectiveMax = maxi(actor.Stats.HealthMaximum - actor.Stats.HealthHumanityThreshold, 1)
	var effectiveCurrent = clampi(actor.Stats.HealthCurrent - actor.Stats.HealthHumanityThreshold, 0, effectiveMax)
	var lowFraction = 1.0 - float(effectiveCurrent) / float(effectiveMax)
	var highFraction = float(effectiveCurrent) / float(effectiveMax)
	var woundedValue = (WEIGHT_LOW_HEALTH - 1.0) * lowFraction * float(effectiveMax)
	var unhurtValue = (WEIGHT_HIGH_HEALTH - 1.0) * highFraction * float(effectiveMax)

	var threatValue = actor.Stats.ThreatCurrent * WEIGHT_THREAT

	var distance = parent.global_position.distance_to(actor.global_position)
	var apSaved = maxf(0.0, (ENGAGEMENT_REFERENCE_METERS - distance) / METERS_PER_AP)
	var proximityValue = apSaved * WEIGHT_PROXIMITY

	#var grudgeValue = Grudges.get(actor, 0.0) * WEIGHT_GRUDGE

	var result = ExplainedThreatValue.new()

	explainThreatEntry(result, "Blood...", woundedValue)
	explainThreatEntry(result, "Juicy...", unhurtValue)
	explainThreatEntry(result, "%s threat" % ActorUtils.getThreatLevelName(actor.Stats.ThreatCurrent), threatValue)
	explainThreatEntry(result, "So close...", proximityValue)

	return result

func PlanTurnActions() -> Array[TurnAction]:
	return [TurnAction.EndTurn()]
