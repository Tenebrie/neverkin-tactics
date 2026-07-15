extends Control
class_name InitiativeBarUI

@onready var portraitContainer: Control = $%PortraitContainer

func _ready() -> void:
	TurnManager.Instance.KnownActorsChanged.connect(rebuildPortraits)
	Actor.SignalBus.ActorDefinitionChanged.connect(rebuildPortraits)

func rebuildPortraits() -> void:
	while portraitContainer.get_child_count() > 0:
		var portrait = portraitContainer.get_child(0)
		portraitContainer.remove_child(portrait)
		portrait.queue_free()

	for i in TurnManager.Instance.playerControlledActors.size():
		var actor = TurnManager.Instance.playerControlledActors[i]
		var portrait: InitiativePortrait = Asset.Instantiate(InitiativePortrait)
		portrait.TrackedActor = actor
		portrait.HotkeyIndex = i
		portraitContainer.add_child(portrait)
