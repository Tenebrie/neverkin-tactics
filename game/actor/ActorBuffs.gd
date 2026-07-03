extends Component
class_name ActorBuffs

signal Changed

func Add(buff: Buff):
	parent.add_child(buff)
	Changed.emit()

func Remove(buff: Buff):
	buff.queue_free()
	Changed.emit()
