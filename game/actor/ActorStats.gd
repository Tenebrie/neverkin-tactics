extends Component
class_name ActorStats

var Name: String:
	get: return parent.Definition.Name
var Alliance: Actor.Alliance:
	get: return parent.Definition.Alliance

var HealthDamageTaken: int = 0
var HealthMaximum: int:
	get: return parent.Definition.HealthMaximum
var HealthHumanityThreshold: int:
	get: return parent.Definition.HealthHumanityThreshold

var HealthCurrent: int:
	get:
		return HealthMaximum - HealthDamageTaken

var HealthThreatened: int = 0

func _ready() -> void:
	TelegraphManager.Instance.TargetsChanged.connect(func(actors: Array[Actor]):
		if actors.has(parent):
			HealthThreatened = TelegraphManager.Instance.CurrentSkill.GetHealthDamage(parent)
		else:
			HealthThreatened = 0
	)

func DealDamage(damage: int):
	HealthDamageTaken = clampi(HealthDamageTaken + damage, 0, HealthMaximum)
	if HealthCurrent <= 0:
		parent.Destroy()

func RestoreHealth(healing: int):
	HealthDamageTaken = clampi(HealthDamageTaken - healing, 0, HealthMaximum)
