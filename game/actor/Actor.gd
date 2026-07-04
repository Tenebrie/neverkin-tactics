@tool
class_name Actor
extends CharacterBody3D

signal DefinitionChanged(def: ActorDefinition)
@export var Definition: ActorDefinition:
	set(v):
		Definition = v
		if isReady:
			loadDefinition()
		DefinitionChanged.emit(v)
		if not Engine.is_editor_hint():
			SignalBus.ActorDefinitionChanged.emit(self)

@onready var isReady = true
@onready var Buffs: ActorBuffs = GetComponent(ActorBuffs)
@onready var Stats: ActorStats = GetComponent(ActorStats)
@onready var actions: ActorActions = GetComponent(ActorActions)
@onready var navigator: ActorNavigator = GetComponent(ActorNavigator)
@onready var targeting: ActorTargeting = GetComponent(ActorTargeting)
@onready var Skills: SkillController = GetComponent(SkillController)
@onready var Behaviour: ActorBehaviour = GetComponent(ActorBehaviour)
@onready var InputProvider: ActorInputProvider = GetComponent(ActorInputProvider)
@onready var Telegraphs: ActorTelegraphs = GetComponent(ActorTelegraphs)

var PhysicalSize:
	get:
		return Definition.PhysicalSize

## This actor is currently selected and being controlled by the player
var IsPlayerControlled: bool:
	get:
		return TurnManager.Instance.CurrentActor == self

var IsAlive: bool:
	get:
		return Stats.HealthCurrent > 0

func GetComponent(type: GDScript[Component]) -> Component:
	for child in get_children():
		if Utils.IsNodeDescendantOf(child, type):
			return child
	return null

func HasComponent(type: GDScript[Component]) -> bool:
	for child in get_children():
		if Utils.IsNodeDescendantOf(child, type):
			return true
	return false

func RemoveComponent(type: GDScript[Component]):
	for child in get_children():
		if Utils.IsNodeDescendantOf(child, type):
			remove_child(child)

func _ready() -> void:
	if Definition != null:
		loadDefinition()

	if Engine.is_editor_hint():
		return
	Repository.All.Register(self)

	if has_node("TokenMeshInstance3D"):
		TurnManager.Instance.CurrentActorChanged.connect(func(actor):
			if actor == self:
				$TokenMeshInstance3D.position.y = RenderHeight.SelectedActor
			else:
				$TokenMeshInstance3D.position.y = -0.02
	)

func loadDefinition():
	if Definition.TokenTexture:
		var material: StandardMaterial3D = $TokenMeshInstance3D.material_override
		material.albedo_texture = Definition.TokenTexture
		var scaleMod = Definition.PhysicalSize / 0.4
		var tween = create_tween().set_parallel()
		tween.tween_property($TokenMeshInstance3D, "scale", Vector3(scaleMod, 1, scaleMod), 0.3)
		tween.tween_property($CollisionShape3D, "scale", Vector3(scaleMod, 1, scaleMod), 0.3)
		$TokenMeshInstance3D.position.x = Definition.TokenOffset.x
		$TokenMeshInstance3D.position.z = Definition.TokenOffset.y

func _exit_tree() -> void:
	if not Engine.is_editor_hint():
		Repository.All.Unregister(self)

func Destroy() -> void:
	Repository.All.Unregister(self)
	Repository.Hovered.Unregister(self)
	SignalBus.ActorDestroyed.emit(self)
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

enum Alliance {
	None = -1,

	Player = 0,
	Neutral = 1,
	Hostile = 2,
}

enum ThreatLevel {
	## Unarmed, not a combatant
	Harmless,
	## Human or common phenomena, armed
	Concerning,
	## Inhuman, or armed with high caliber weapons
	Dangerous,
	## Actively threatening, monstrous or infamous
	Deadly,
	## Immediate and undeniable existential crisis
	Existential,
}

static var SignalBus: SignalBusImplementation = SignalBusImplementation.new()
class SignalBusImplementation:
	signal ActorDefinitionChanged(actor: Actor)
	signal ActorDestroyed(actor: Actor)
	signal ActorSelectedSkillChanged(actor: Actor, current: Skill, previous: Skill)
