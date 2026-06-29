extends Control
class_name SkillBar

@onready var buttonContainer: Control = $%ButtonContainer

@onready var CurrentActor = SignalTracker.new(
	func(actor: Actor): return actor.Skills.SkillsChanged,
	rebuildItems
)

func _ready() -> void:
	TurnManager.Instance.CurrentActorChanged.connect(connectSignals)
	TurnManager.Instance.CurrentActorChanged.connect(rebuildItems)

func connectSignals(actor: Actor) -> void:
	CurrentActor.Track(actor)

func rebuildItems() -> void:
	while buttonContainer.get_child_count() > 0:
		buttonContainer.remove_child(buttonContainer.get_child(0))

	var controller = TurnManager.Instance.CurrentActor.Skills
	for i in range(8):
		var newItem = Asset.Instantiate(SkillBarItem)
		newItem.TrackedSkill = controller.GetByIndex(i)
		newItem.HotkeyIndex = i
		buttonContainer.add_child(newItem)
