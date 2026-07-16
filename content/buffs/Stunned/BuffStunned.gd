extends Buff
class_name BuffStunned

const Damage = 2
const ActionPointsLost = 1

func _prepare() -> void:
	parent.turnStarted.connect(func():
		parent.actions.ConsumeActionPoints(ActionPointsLost)
	)
