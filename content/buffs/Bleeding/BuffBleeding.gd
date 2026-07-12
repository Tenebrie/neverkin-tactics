extends Buff
class_name BuffBleeding

const DamagePerStack = 1

var sourceSkill: Skill

var damageToDeal: int:
	get:
		return DamagePerStack * Intensity

func _prepare():
	parent.turnEnded.connect(func():
		await MainCamera.lock(parent)
		parent.Stats.DealDamage(DamageInstance.ForExtraSkillEffect(sourceSkill, damageToDeal))
		await MainCamera.unlock()
	)

static func Build(sourceSkill: Skill) -> BuffBleeding:
	var buff = BuffBleeding.new()
	buff.sourceSkill = sourceSkill
	return buff
