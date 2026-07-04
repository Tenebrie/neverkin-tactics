extends Component
class_name Buff

@export var Intensity: int = 1

@export var Owner: Node:
	set(v):
		if Owner:
			Owner.tree_exited.disconnect(queue_free)
		Owner = v
		Owner.tree_exited.connect(queue_free)
