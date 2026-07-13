extends Skill
class_name SkillSecondWind

var resourceRestored = 0.5

var healthRestored: int:
	get:
		return ceili(parent.stats.healthMaximum * resourceRestored)
var manaRestored: int:
	get:
		return ceili(parent.stats.manaMaximum * resourceRestored)

var healthRestoredString: String:
	get:
		if parent.stats.healthMaximum <= 0:
			return ""
		return "[color=orange]Health restored:[/color] %d"%healthRestored
var manaRestoredString: String:
	get:
		if parent.stats.manaMaximum <= 0:
			return ""
		return "[color=orange]Mana restored:[/color] %d"%manaRestored

func _prepare() -> void:
	var telegraph = TelegraphPreset.SelfCast.new()
	telegraph.HealthPromise = healthRestored
	telegraph.ManaPromise = manaRestored
	definition.telegraphs = [
		telegraph
	]

func _cast(_targets: TargetData) -> void:
	parent.stats.restoreHealth(healthRestored)
	parent.stats.restoreMana(manaRestored)
