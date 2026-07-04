extends Component
class_name ActorStats

signal DamageTaken(value: int, source: Actor)

var Name: String:
	get: return Parent.Definition.Name
var Alliance: Actor.Alliance:
	get: return Parent.Definition.Alliance

#region Health
var HealthDamageTaken: int = 0
var HealthMaximum: int:
	get: return Parent.Definition.HealthMaximum
var HealthHumanityThreshold: int:
	get: return Parent.Definition.HealthHumanityThreshold

var HealthCurrent: int:
	get:
		return HealthMaximum - HealthDamageTaken

var HealthThreatened: int = 0

func _parentReady() -> void:
	if Parent.Buffs:
		Parent.Buffs.Changed.connect(func():
			HealthThreatened = Parent.Buffs.Count(BuffHealthThreat)
		)

func DealDamage(damage: int, source: Actor):
	HealthDamageTaken = clampi(HealthDamageTaken + damage, 0, HealthMaximum)
	if HealthCurrent <= 0:
		Parent.Destroy()
	DamageTaken.emit(damage, source)

func RestoreHealth(healing: int):
	HealthDamageTaken = clampi(HealthDamageTaken - healing, 0, HealthMaximum)
#endregion
#region Threat
var ThreatCurrent: float:
	get:
		var inhumanVitalityThreat = 1 if HealthCurrent <= HealthHumanityThreshold else 0
		return Parent.Definition.PerceivedThreat + ThreatGenerated + inhumanVitalityThreat
var ThreatGenerated: float = 0

func GenerateThreat(value: float):
	ThreatGenerated = clampf(ThreatGenerated + value, 0.0, 10.0)

func ReleaseThreat(value: float):
	GenerateThreat(-value)
#endregion

#static var SignalBus: SignalBusImplementation = SignalBusImplementation.new()
#class SignalBusImplementation:
	#signal DamageTaken(actor: Actor, value: float, source: Actor)
