extends Buff
class_name BuffQuickened

const ActionPointsGained = 1

func _prepare() -> void:
	parent.turnEnded.connect(func():
		parent.actions.AddTemporaryActionPoints(ActionPointsGained)
	)
