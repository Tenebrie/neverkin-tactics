extends Component
class_name ActorStats

var Name: String:
	get: return parent.Definition.Name

var HealthDamageTaken: int = 0
var HealthMaximum: int:
	get: return parent.Definition.HealthMaximum
var HealthHumanityThreshold: int:
	get: return parent.Definition.HealthHumanityThreshold

var HealthCurrent: int:
	get:
		return HealthMaximum - HealthDamageTaken

func DealDamage(damage: int):
	HealthDamageTaken += damage
	HealthDamageTaken = clampi(HealthDamageTaken + damage, 0, HealthMaximum)

func RestoreHealth(healing: int):
	HealthDamageTaken = clampi(HealthDamageTaken - healing, 0, HealthMaximum)
