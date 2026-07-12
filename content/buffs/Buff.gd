extends Component
class_name Buff

var controller: ActorBuffs
var definition: BuffDefinition

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
		Duration = definition.durationTurns

	TurnManager.Instance.FactionTurnEnded.connect(func(faction):
		if faction != parent.faction:
			return

		Duration -= 1
		if Duration <= 0:
			parent.buffs.Remove(self)
	)
	_prepare()

func _prepare() -> void:
	pass

@export var Intensity: int = 1:
	set(v):
		if Intensity == v:
			return
		Intensity = v
		if is_node_ready():
			parent.buffs.Changed.emit()

@export var Duration: int = 1:
	set(v):
		if Duration == v:
			return
		Duration = v
		if is_node_ready():
			parent.buffs.Changed.emit()

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

enum StackType {
	## No special handling
	Parallel,
	## If the buff with the same intensity is already present, combine their durations
	StacksDuration,
	## Combine intensity, set remaining duration to the longest
	StacksIntensity,
	## Remove all others, apply latest
	None,
}
