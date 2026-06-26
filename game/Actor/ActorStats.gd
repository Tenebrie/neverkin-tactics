extends Component
class_name ActorStats

@export var Name: String = "Unknown"

@export var HealthDamageTaken: int = 0
@export var HealthMaximum: int = 3
@export var HealthHumanityThreshold: int = 0

var HealthCurrent: int:
	get:
		return HealthMaximum - HealthDamageTaken

func DealDamage(damage: int):
	HealthDamageTaken += damage
	HealthDamageTaken = clampi(HealthDamageTaken + damage, 0, HealthMaximum)

func RestoreHealth(healing: int):
	HealthDamageTaken = clampi(HealthDamageTaken - healing, 0, HealthMaximum)
