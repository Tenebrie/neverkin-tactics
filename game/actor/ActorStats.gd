extends Component
class_name ActorStats

signal damageTaken(damage: DamageInstance)
signal manaSpent(damage: DamageInstance)

var Name: String:
	get: return parent.definition.Name
var Faction: Actor.Faction:
	get: return parent.faction

#region Engine events
func _parentReady() -> void:
	if parent.buffs:
		parent.buffs.Changed.connect(func():
			var selectedSkillCost = parent.Skills.SelectedSkill.HealthCost if parent.Skills.SelectedSkill else 0
			healthThreatened = parent.buffs.Count(BuffHealthThreat) + selectedSkillCost
		)
	if parent.Skills:
		parent.Skills.SelectedSkillChanged.connect(func(skill):
			if skill:
				healthThreatened = parent.buffs.Count(BuffHealthThreat) + skill.HealthCost
				manaThreatened = skill.definition.ManaCost
			else:
				healthThreatened = parent.buffs.Count(BuffHealthThreat)
				manaThreatened = 0
		)
#endregion

#region Health
var healthDamageTaken: int = 0
var healthMaximum: int:
	get: return parent.definition.healthMaximum
var healthHumanityThreshold: int:
	get: return parent.definition.healthHumanityThreshold

var healthCurrent: int:
	get:
		return healthMaximum - healthDamageTaken

var healthThreatened: int = 0

func dealDamage(damage: DamageInstance):
	healthDamageTaken = clampi(healthDamageTaken + damage.Value, 0, healthMaximum)
	if healthCurrent <= 0:
		parent.Destroy()
	damageTaken.emit(damage)

func dealSkillDamage(targets: Skill.TargetData):
	dealDamage(DamageInstance.ForSkillCast(parent, targets))
#endregion

#region Mana
var manaMissing: int = 0
var manaMaximum: int:
	get: return parent.definition.ManaMaximum

var manaCurrent: int:
	get:
		return manaMaximum - manaMissing

var manaThreatened: int = 0

func consumeMana(damage: DamageInstance):
	manaMissing = clampi(manaMissing + damage.Value, 0, manaMaximum)
	manaSpent.emit(damage)
#endregion

#region Threat
var threatCurrent: float:
	get:
		var inhumanVitalityThreat = 1 if healthCurrent <= healthHumanityThreshold else 0
		return parent.definition.PerceivedThreat + threatGenerated + inhumanVitalityThreat
var threatGenerated: float = 0

func generateThreat(value: float):
	threatGenerated = clampf(threatGenerated + value, 0.0, 10.0)

func releaseThreat(value: float):
	generateThreat(-value)
#endregion

#static var SignalBus: SignalBusImplementation = SignalBusImplementation.new()
#class SignalBusImplementation:
	#signal damageTaken(actor: Actor, value: float, source: Actor)
