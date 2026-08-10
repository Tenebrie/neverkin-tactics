@tool
extends HBoxContainer
class_name EncounterControlsFactionActor

var count: int:
	get:
		return roundi(counter.value)
	set(value):
		counter.value = value

var options: Array[EncounterControlsFaction.ActorEntry]
var selectedOption: EncounterControlsFaction.ActorEntry:
	get:
		return options[dropdown.selected]

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
