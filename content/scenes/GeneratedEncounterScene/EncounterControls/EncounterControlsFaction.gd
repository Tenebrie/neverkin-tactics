@tool
extends PanelContainer
class_name EncounterControlsFaction

@export var faction: Actor.Faction = Actor.Faction.None

@onready var nameLabel: Label = %FactionNameLabel
@onready var actorContainer: VBoxContainer = %ActorContainer

var options: Array[ActorEntry]

class ActorEntry:
	var actorName: String
	var asset: PackedScene

func _ready():
	_generateOptions()
	nameLabel.text = ActorUtils.getFactionName(faction)
	_publishOptions()

func _generateOptions():
	if faction == Actor.Faction.Kin:
		_pushOption("Ivera", preload("res://content/actors/Ivera/Ivera.tscn"))
		_pushOption("Kamilla", preload("res://content/actors/Kamilla/Kamilla.tscn"))
		_pushOption("Char", preload("res://content/actors/Char/Char.tscn"))
	elif faction == Actor.Faction.Wolfpack:
		_pushOption("Brawler", preload("res://content/actors/WolfpackBrawler/WolfpackBrawler.tscn"))
		_pushOption("Trooper", preload("res://content/actors/WolfpackTrooper/WolfpackTrooper.tscn"))

func _pushOption(actorName: String, asset: PackedScene) -> void:
	var entry = ActorEntry.new()
	entry.actorName = actorName
	entry.asset = asset
	options.push_back(entry)

func _publishOptions():
	for child in actorContainer.get_children():
		child.queue_free()

	if faction == Actor.Faction.Kin:
		_addActorEntry(1, 0)
		_addActorEntry(1, 1)
		_addActorEntry(1, 2)

	if faction == Actor.Faction.Wolfpack:
		_addActorEntry(1, 0)
		_addActorEntry(2, 1)

func _onAddActorButtonPressed() -> void:
	_addActorEntry()

func _addActorEntry(count: int = 1, selected: int = 0):
	var component = Asset.Instantiate(EncounterControlsFactionActor)
	component.options = options
	actorContainer.add_child(component)
	component.count = count
	component.select(selected)
