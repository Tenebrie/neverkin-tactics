extends Component
class_name Buff

var controller: ActorBuffs
var definition: BuffDefinition

var turnsRemaining = -1

func _init():
	tree_entered.connect(func():
		controller = get_parent()
		parent = controller.parent
	, CONNECT_ONE_SHOT)

func _ready() -> void:
	if not definition:
		var scriptPath = get_script().resource_path
		var definitionPath = scriptPath.get_basename() + ".tres"
		if ResourceLoader.exists(definitionPath):
			definition = load(definitionPath).duplicate() as BuffDefinition

	if definition:
		name = definition.name
	_prepare()

func _prepare() -> void:
	pass

@export var Intensity: int = 1:
	set(v):
		if Intensity == v:
			return
		Intensity = v
		if is_node_ready():
			parent.Buffs.Changed.emit()

@export var Owner: Node:
	set(v):
		if Owner:
			Owner.tree_exited.disconnect(queue_free)
		Owner = v
		Owner.tree_exited.connect(queue_free)

enum Alignment {
	Neutral,
	Positive,
	Negative
}
