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

func collect() -> EncounterControls.FactionToSpawn:
	var factionToSpawn = EncounterControls.FactionToSpawn.new()
	factionToSpawn.faction = faction
	for entry in actorContainer.get_children():
		if entry is EncounterControlsFactionActor actor:
			for i in actor.count:
				factionToSpawn.actors.push_back(entry.selectedOption.asset)
	return factionToSpawn

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

func getRows() -> Array[EncounterControlsActorRow]:
	var rows: Array[EncounterControlsActorRow] = []
	for entry in actorContainer.get_children():
		if entry is EncounterControlsFactionActor actor:
			rows.push_back(_makeRow(actor.count, actor.dropdown.selected))
	return rows

func setRows(rows: Array[EncounterControlsActorRow]) -> void:
	for child in actorContainer.get_children():
		child.queue_free()
	for row in rows:
		_addActorEntry(row.count, row.selected)

func reset() -> void:
	_publishOptions()

func _publishOptions():
	var rows: Array[EncounterControlsActorRow] = []
	if faction == Actor.Faction.Kin:
		rows = [_makeRow(count: 1, selected: 0), _makeRow(count: 1, selected: 1), _makeRow(count: 1, selected: 2)]
	elif faction == Actor.Faction.Wolfpack:
		rows = [_makeRow(count: 1, selected: 0), _makeRow(count: 2, selected: 1)]
	setRows(rows)

func _makeRow(count: int, selected: int) -> EncounterControlsActorRow:
	var row = EncounterControlsActorRow.new()
	row.count = count
	row.selected = selected
	return row

func _onAddActorButtonPressed() -> void:
	_addActorEntry()

func _addActorEntry(count: int = 1, selected: int = 0):
	var component = Asset.Instantiate(EncounterControlsFactionActor)
	component.options = options
	actorContainer.add_child(component)
	component.count = count
	component.select(selected)
