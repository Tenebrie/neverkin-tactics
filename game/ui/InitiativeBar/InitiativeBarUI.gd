extends Control
class_name InitiativeBarUI

@onready var portraitContainer: Control = $%PortraitContainer

func _ready() -> void:
	TurnManager.Instance.KnownActorsChanged.connect(rebuildPortraits)

func rebuildPortraits() -> void:
	while portraitContainer.get_child_count() > 0:
		portraitContainer.remove_child(portraitContainer.get_child(0))

	for i in TurnManager.Instance.PlayerControlledActors.size():
		var actor = TurnManager.Instance.PlayerControlledActors[i]
		var portrait: InitiativePortrait = Asset.Instantiate(InitiativePortrait)
		portrait.TrackedActor = actor
		portrait.HotkeyIndex = i
		portraitContainer.add_child(portrait)
