@tool
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
	Repository.All.Register(self)
	if Definition != null:
		var material: StandardMaterial3D = $MeshInstance3D.material_override
		material.albedo_texture = Definition.TokenTexture

func _exit_tree() -> void:
	Repository.All.Unregister(self)

func Destroy() -> void:
	Repository.All.Unregister(self)
	Repository.Hovered.Unregister(self)
	queue_free()

#region Repository
class Repository:
	static var All: Implementation = Implementation.new()
	static var Hovered: Implementation = Implementation.new()

	class Implementation:
		var List: Array[Actor] = []

		func Register(actor: Actor):
			var index = List.find(actor)
			if index > 0:
				return
			List.push_back(actor)

		func Unregister(actor: Actor):
			var index = List.find(actor)
			if index < 0:
				return
			List.remove_at(index)
#endregion
