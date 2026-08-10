extends Control
class_name InitiativeBarUI

@onready var portraitContainer: Control = $%PortraitContainer

func _ready() -> void:
	TurnManager.Instance.KnownActorsChanged.connect(rebuildPortraits)
	Actor.SignalBus.ActorDefinitionChanged.connect(rebuildPortraits)

func rebuildPortraits() -> void:
	for child in portraitContainer.get_children():
		child.queue_free()

	for i in TurnManager.Instance.playerControlledActors.size():
		var actor = TurnManager.Instance.playerControlledActors[i]
		var portrait: InitiativePortrait = Asset.Instantiate(InitiativePortrait)
		portrait.TrackedActor = actor
		portrait.HotkeyIndex = i
		portraitContainer.add_child(portrait)
