extends Component
class_name ActorBuffs

signal Changed

func Add(buff: Buff) -> void:
	Parent.add_child(buff)
	Changed.emit()

func Count(buffClass: GDScript[Buff]) -> int:
	var total = 0
	for child in Parent.get_children():
		if child is Buff buff and Utils.IsNodeDescendantOf(child, buffClass) and not child.is_queued_for_deletion():
			total += buff.Intensity
	return total

func Remove(buff: Buff) -> void:
	buff.queue_free()
	Changed.emit()
