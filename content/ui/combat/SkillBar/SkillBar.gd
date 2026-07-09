extends Control
class_name SkillBar

@onready var commonBarContainer: Control = $%CommonBarContainer
@onready var mainBarContainer: Control = $%MainBarContainer

@onready var activePlayerActor = SignalTracker.new(
	func(actor: Actor): return actor.Skills.SkillsChanged,
	rebuildItems
)

func _ready() -> void:
	TurnManager.Instance.CurrentPlayerActorChanged.connect(connectSignals)

func connectSignals(actor: Actor) -> void:
	activePlayerActor.Track(actor)
	rebuildItems()

func rebuildItems() -> void:
	for child in commonBarContainer.get_children():
		child.queue_free()
	for child in mainBarContainer.get_children():
		child.queue_free()

	var controller = TurnManager.Instance.activePlayerActor.Skills
	for i in range(8):
		var newItem = Asset.Instantiate(SkillBarItem)
		var skill = controller.commonSkillGroup.GetByIndex(i)
		if skill:
			newItem.TrackedSkill = controller.commonSkillGroup.GetByIndex(i)
			if skill.Definition.Hotkey:
				newItem.Hotkey = skill.Definition.Hotkey
		else:
			newItem.Transparent = true
		commonBarContainer.add_child(newItem)

	for i in range(8):
		var newItem = Asset.Instantiate(SkillBarItem)
		var skill = controller.GetByIndex(i)
		if skill:
			newItem.TrackedSkill = skill
			if skill.Definition.Hotkey:
				newItem.Hotkey = skill.Definition.Hotkey
			else:
				var hotkey = InputEventKey.new()
				hotkey.keycode = KEY_1 + i as Key
				newItem.Hotkey = hotkey
		mainBarContainer.add_child(newItem)
