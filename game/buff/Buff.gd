extends Component
class_name Buff

@export var Intensity: int = 1:
	set(v):
		if Intensity == v:
			return
		Intensity = v
		if is_node_ready():
			Parent.Buffs.Changed.emit()

@export var Owner: Node:
	set(v):
		if Owner:
			Owner.tree_exited.disconnect(queue_free)
		Owner = v
		Owner.tree_exited.connect(queue_free)
