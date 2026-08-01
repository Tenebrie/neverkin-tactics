extends Buff
class_name SkillGriffonGripBuff

func _process(_delta: float) -> void:
	if Owner is not Actor actor:
		return
	var dist = ActorUtils.flatDistanceBetweenActors(actor, parent)
	if dist > 0.5:
		parent.buffs.Remove(self)
