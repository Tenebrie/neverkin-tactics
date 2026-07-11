extends Component
class_name ActorStats

signal DamageTaken(damage: DamageInstance)

var Name: String:
	get: return parent.definition.Name
var Faction: Actor.Faction:
	get: return parent.faction

#region Health
var HealthDamageTaken: int = 0
var HealthMaximum: int:
	get: return parent.definition.HealthMaximum
var HealthHumanityThreshold: int:
	get: return parent.definition.HealthHumanityThreshold

var HealthCurrent: int:
	get:
		return HealthMaximum - HealthDamageTaken

var HealthThreatened: int = 0

func _parentReady() -> void:
	if parent.Buffs:
		parent.Buffs.Changed.connect(func():
			HealthThreatened = parent.Buffs.Count(BuffHealthThreat)
		)

func DealDamage(damage: DamageInstance):
	HealthDamageTaken = clampi(HealthDamageTaken + damage.Value, 0, HealthMaximum)
	if HealthCurrent <= 0:
		parent.Destroy()
	DamageTaken.emit(damage)

func DealSkillDamage(targets: Skill.TargetData):
	DealDamage(DamageInstance.ForSkillCast(parent, targets))
#endregion
#region Threat
var ThreatCurrent: float:
	get:
		var inhumanVitalityThreat = 1 if HealthCurrent <= HealthHumanityThreshold else 0
		return parent.definition.PerceivedThreat + ThreatGenerated + inhumanVitalityThreat
var ThreatGenerated: float = 0

func GenerateThreat(value: float):
	ThreatGenerated = clampf(ThreatGenerated + value, 0.0, 10.0)

func ReleaseThreat(value: float):
	GenerateThreat(-value)
#endregion

#static var SignalBus: SignalBusImplementation = SignalBusImplementation.new()
#class SignalBusImplementation:
	#signal DamageTaken(actor: Actor, value: float, source: Actor)
