class_name Actor
extends CharacterBody3D

@export var Definition: ActorDefinition

@onready var stats: ActorStats = $ActorStats
@onready var actions: ActorActions = $ActorActions
@onready var navigator: ActorNavigator = $ActorNavigator
@onready var targeting: ActorTargeting = $ActorTargeting
@onready var Skills: SkillController = $SkillController

## This actor is currently selected and being controlled by the player
var IsPlayerControlled: bool:
	get:
		return TurnManager.Instance.CurrentActor == self

func GetComponent(type: GDScript[Component]) -> Component:
	for child in get_children():
		var script: GDScript = child.get_script()
		if script != null and ActorUtils.GetClassAncestors(script).has(type):
			return child
	return null

func HasComponent(type: GDScript[Component]) -> bool:
	for child in get_children():
		var script: GDScript = child.get_script()
		if script != null and ActorUtils.GetClassAncestors(script).has(type):
			return true
	return false

func _ready() -> void:
	Repository.Register(self)

func _exit_tree() -> void:
	Repository.Unregister(self)

#region Repository
class Repository:
	static var AllActors: Array[Actor] = []

	static func Register(actor: Actor):
		var index = AllActors.find(actor)
		if index > 0:
			return
		AllActors.push_back(actor)

	static func Unregister(actor: Actor):
		var index = AllActors.find(actor)
		if index < 0:
			return
		AllActors.remove_at(index)
#endregion
