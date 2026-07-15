extends Buff
class_name BuffSlowed

const ActionPointsLost = 1

func _prepare() -> void:
	parent.turnStarted.connect(func():
		parent.actions.ConsumeActionPoints(ActionPointsLost)
	)
