extends ActorBehaviourWorldControlled

const METERS_PER_AP: float = 5.0
const ENGAGEMENT_REFERENCE_METERS: float = 20.0
const HIGHLIGHT_THRESHOLD: float = 2.0

@export var WEIGHT_LOW_HEALTH: float = 2.0
@export var WEIGHT_HIGH_HEALTH: float = 1.0
@export var WEIGHT_THREAT: float = 1.0
@export var WEIGHT_PROXIMITY: float = 1.0
@export var WEIGHT_GRUDGE: float = 1.0

var Grudges: Dictionary[Actor, float] = {}

func _parentReady() -> void:
	super._parentReady()
	Parent.Stats.DamageTaken.connect(func(value, source):
		RecordGrudge(source, value)
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
	result.Total = woundedValue + unhurtValue + threatValue + proximityValue + grudgeValue

	addHighlight(result, "Wounded", woundedValue)
	addHighlight(result, "Unhurt", unhurtValue)
	addHighlight(result, "%s threat" % ActorUtils.GetThreatLevelName(actor.Stats.ThreatCurrent), threatValue)
	addHighlight(result, "Within reach", proximityValue)
	addHighlight(result, "Owes me blood", grudgeValue)

	return result

func addHighlight(result: ExplainedThreatValue, label: String, value: float) -> void:
	if value >= HIGHLIGHT_THRESHOLD:
		result.Highlights[label] = value
