@tool
extends HBoxContainer
class_name EncounterControlsFactionActor

@export var count = 1

var options: Array[EncounterControlsFaction.ActorEntry]

@onready var removeActorButton: Button = %RemoveActorButton
@onready var counter: SpinBox = %CountSpinBox
@onready var dropdown: OptionButton = %OptionsDropdown

func _ready():
	for index in options.size():
		var option = options[index]
		dropdown.add_item(option.actorName, index)
	dropdown.selected = 0

func select(option: int):
	dropdown.selected = option


func _onRemoveActorButtonPressed() -> void:
	queue_free()
