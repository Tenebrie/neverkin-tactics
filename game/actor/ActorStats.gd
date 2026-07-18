extends Component
class_name ActorStats

signal damageTaken(damage: DamageInstance)
signal healthChanged(current: int)
signal manaSpent(damage: DamageInstance)
signal manaChanged(current: int)

var Name: String:
	get: return parent.definition.Name
var Faction: Actor.Faction:
	get: return parent.faction

#region Engine events
func _parentReady() -> void:
	if parent.buffs:
		parent.buffs.Changed.connect(func():
			var selectedSkillHealthCost = parent.Skills.SelectedSkill.HealthCost if parent.Skills.SelectedSkill else 0
			var selectedSkillManaCost = parent.Skills.SelectedSkill.ManaCost if parent.Skills.SelectedSkill else 0
			if parent.actions.isFreeRecast():
				selectedSkillHealthCost = 0
				selectedSkillManaCost = 0
			healthThreatened = parent.buffs.Count(BuffHealthThreat) + selectedSkillHealthCost
			healthPromised = parent.buffs.Count(BuffHealthPromise)
			manaThreatened = parent.buffs.Count(BuffManaThreat) + selectedSkillManaCost
			manaPromised = parent.buffs.Count(BuffManaPromise)
		)
	if parent.Skills:
		parent.Skills.SelectedSkillChanged.connect(func(skill):
			if skill and not parent.actions.isFreeRecast():
				healthThreatened = parent.buffs.Count(BuffHealthThreat) + skill.HealthCost
				healthPromised = parent.buffs.Count(BuffHealthPromise)
				manaThreatened = parent.buffs.Count(BuffManaThreat) + skill.ManaCost
				manaPromised = parent.buffs.Count(BuffManaPromise)
			else:
				healthThreatened = parent.buffs.Count(BuffHealthThreat)
				healthPromised = parent.buffs.Count(BuffHealthPromise)
				manaThreatened = parent.buffs.Count(BuffManaThreat)
				manaPromised = parent.buffs.Count(BuffManaPromise)
		)
#endregion

#region Health
var healthDamageTaken: int = 0
var healthMaximumDamageTaken: int = 0
var healthMaximum: int:
	get: return parent.definition.healthMaximum - healthMaximumDamageTaken
var healthHumanityThreshold: int:
	get: return parent.definition.healthHumanityThreshold

var healthCurrent: int:
	get:
		return healthMaximum - healthDamageTaken

var healthThreatened: int = 0
var healthPromised: int = 0

func applyDamageInstance(damage: DamageInstance):
	if damage.Value > 0:
		dealDamage(damage)
	else:
		restoreHealth(-damage.Value)

func dealDamage(damage: DamageInstance):
	healthDamageTaken = clampi(healthDamageTaken + damage.Value, 0, healthMaximum)
	if healthCurrent <= 0:
		parent.Destroy()
	damageTaken.emit(damage)
	healthChanged.emit(healthCurrent)

func reduceHealthMaximum(value: int):
	healthMaximumDamageTaken += value
	healthDamageTaken -= mini(healthDamageTaken, value)
	healthChanged.emit(healthCurrent)

func dealSkillDamage(targets: Skill.TargetData):
	var instance = DamageInstance.ForSkillCast(parent, targets)
	if instance.Value > 0:
		dealDamage(instance)
	else:
		restoreHealth(-instance.Value)

func restoreHealth(value: int):
	healthDamageTaken = clampi(healthDamageTaken - value, 0, healthMaximum)
	healthChanged.emit(healthCurrent)
#endregion

#region Mana
var manaMissing: int = 0
var manaMaximum: int:
	get: return parent.definition.ManaMaximum

var manaCurrent: int:
	get:
		return manaMaximum - manaMissing

var manaThreatened: int = 0
var manaPromised: int = 0

func consumeMana(damage: DamageInstance):
	manaMissing = clampi(manaMissing + damage.Value, 0, manaMaximum)
	manaSpent.emit(damage)
	manaChanged.emit(manaCurrent)

func restoreMana(value: int):
	manaMissing = clampi(manaMissing - value, 0, manaMaximum)
	manaChanged.emit(manaCurrent)
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
