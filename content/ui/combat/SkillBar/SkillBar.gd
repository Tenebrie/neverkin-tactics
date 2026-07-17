extends Control
class_name SkillBar

@onready var commonBarContainer: Control = $%CommonBarContainer
@onready var mainBarContainer: Control = $%MainBarContainer
@onready var sounds: SkillBarSounds = $SkillBarSounds

@onready var activePlayerActor = SignalTracker.new(
	func(actor: Actor): return actor.Skills.SkillsChanged,
	rebuildItems
)

func _ready() -> void:
	TurnManager.Instance.CurrentPlayerActorChanged.connect(connectSignals)
	for index in commonBarContainer.get_child_count():
		var child = commonBarContainer.get_child(index)
		if child is SkillBarItem item:
			_connectBarItemSignals(item, index)
	for index in mainBarContainer.get_child_count():
		var child = mainBarContainer.get_child(index)
		if child is SkillBarItem item:
			_connectBarItemSignals(item, index)

func connectSignals(actor: Actor) -> void:
	activePlayerActor.Track(actor)
	rebuildItems()

func _connectBarItemSignals(item: SkillBarItem, index: int) -> void:
	item.pressed.connect(sounds.playPressed)
	item.released.connect(sounds.playReleased)
	item.declined.connect(sounds.playDeclined.bind(index))

func rebuildItems() -> void:
	if not TurnManager.Instance.activePlayerActor:
		return
	var controller = TurnManager.Instance.activePlayerActor.Skills
	for i in range(8):
		var newItem: SkillBarItem
		if commonBarContainer.get_child_count() > i:
			newItem = commonBarContainer.get_child(i)
		else:
			newItem = Asset.Instantiate(SkillBarItem)
			_connectBarItemSignals(newItem, i)
			commonBarContainer.add_child(newItem)
		var skill = controller.commonSkillGroup.GetByIndex(i)
		newItem.Transparent = skill == null
		newItem.Hotkey = skill.definition.Hotkey if skill and skill.definition.Hotkey else null
		newItem.TrackedSkill = skill

	for i in range(8):
		var newItem: SkillBarItem
		if mainBarContainer.get_child_count() > i:
			newItem = mainBarContainer.get_child(i)
		else:
			newItem = Asset.Instantiate(SkillBarItem)
			_connectBarItemSignals(newItem, i)
			mainBarContainer.add_child(newItem)
		var skill = controller.GetByIndex(i)
		var hotkey: InputEventKey = null
		if skill:
			if skill.definition.Hotkey:
				hotkey = skill.definition.Hotkey
			else:
				hotkey = InputEventKey.new()
				hotkey.keycode = KEY_1 + i as Key
		newItem.Transparent = false
		newItem.Hotkey = hotkey
		newItem.TrackedSkill = skill
