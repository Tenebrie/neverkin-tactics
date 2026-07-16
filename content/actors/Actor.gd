@tool
class_name Actor
extends CharacterBody3D

@onready var isReady = true

#region Engine Events
func _ready() -> void:
	if definition != null:
		loadDefinition()

	pronouns = Pronouns.FromPreset(definition.pronouns)
	if Engine.is_editor_hint():
		return
	Repository.All.Register(self)
	Repository.Alive.Register(self)

	#if has_node("TokenMeshInstance3D"):
		#TurnManager.Instance.CurrentActorChanged.connect(func(actor):
			#if actor == self:
				##$TokenMeshInstance3D.position.y = RenderHeight.SelectedActor
				#$TokenMeshInstance3D.position.y = 0
			#else:
				#$TokenMeshInstance3D.position.y = 0
	#)

	_setupProxySignals()

func _exit_tree() -> void:
	if not Engine.is_editor_hint():
		Repository.All.Unregister(self)
		Repository.Alive.Unregister(self)
		Repository.Hovered.Unregister(self)
#endregion

#region Proxy Getters
var physicalSize: float:
	get:
		return definition.physicalSize
var pronouns: Pronouns
var faction: Faction:
	get:
		if buffs:
			var mindControl = buffs.Get(BuffMindControl) as BuffMindControl
			if mindControl:
				return mindControl.faction
		return definition.Faction
var movementSpeedPerAction: float:
	get:
		var base = definition.MovementSpeedPerActionPoint
		if not buffs:
			return base
		if buffs.Has(BuffCrippled):
			base /= 2.0
		if buffs.Has(BuffStim):
			base *= 2.0
		return base
var initiative: float:
	get:
		return definition.initiative
var isShapeshifted: bool:
	get:
		return definition.enablesShifted
#endregion

#region Proxy signals
signal beforeTurnStarted()
signal turnStarted()
signal beforeTurnEnded()
signal turnEnded()

func _setupProxySignals():
	TurnManager.Instance.BeforeFactionTurnStarted.connect(func(finishingFaction):
		if finishingFaction == faction:
			await SignalUtils.emitAsync([beforeTurnStarted])
	)
	TurnManager.Instance.FactionTurnStarted.connect(func(finishingFaction):
		if finishingFaction == faction:
			await SignalUtils.emitAsync([turnStarted])
	)
	TurnManager.Instance.BeforeFactionTurnEnded.connect(func(finishingFaction):
		if finishingFaction == faction:
			await SignalUtils.emitAsync([beforeTurnEnded])
	)
	TurnManager.Instance.FactionTurnEnded.connect(func(finishingFaction):
		if finishingFaction == faction:
			await SignalUtils.emitAsync([turnEnded])
	)
#endregion

#region Components
@onready var buffs: ActorBuffs = GetComponent(ActorBuffs)
@onready var stats: ActorStats = GetComponent(ActorStats)
@onready var actions: ActorActions = GetComponent(ActorActions)
@onready var navigator: ActorNavigator = GetComponent(ActorNavigator)
@onready var targeting: ActorTargeting = GetComponent(ActorTargeting)
@onready var Skills: SkillController = GetComponent(SkillController)
@onready var Behaviour: ActorBehaviour = GetComponent(ActorBehaviour)
@onready var InputProvider: ActorInputProvider = GetComponent(ActorInputProvider)
@onready var telegraphs: ActorTelegraphs = GetComponent(ActorTelegraphs)

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
#endregion

#region Definition
signal DefinitionChanged(def: ActorDefinition)

@export var definition: ActorDefinition:
	set(v):
		definition = v
		if isReady:
			loadDefinition()
		DefinitionChanged.emit(v)
		if not Engine.is_editor_hint():
			SignalBus.ActorDefinitionChanged.emit(self)

func loadDefinition():
	if not definition:
		return

	if not Engine.is_editor_hint():
		name = definition.Name
	if definition.TokenTexture:
		var material: StandardMaterial3D = $TokenMeshInstance3D.material_override
		material.albedo_texture = definition.TokenTexture
		var scaleMod = definition.physicalSize / 0.4
		var tween = create_tween().set_parallel()
		tween.tween_property($TokenMeshInstance3D, "scale", Vector3(scaleMod, 1, scaleMod), 0.3)
		tween.tween_property($CollisionShape3D, "scale", Vector3(scaleMod, 1, scaleMod), 0.3)
		$TokenMeshInstance3D.position.x = definition.TokenOffset.x
		$TokenMeshInstance3D.position.z = definition.TokenOffset.y
#endregion

#region Lifecycle (Game)
signal destroyed

var isAlive: bool:
	get:
		return stats.healthCurrent > 0 and not isDead
var isDead = false

func Destroy() -> void:
	isDead = true
	collision_mask = 0
	collision_layer = 0
	Repository.Alive.Unregister(self)
	fadeOut()
	destroyed.emit()
	SignalBus.ActorDestroyed.emit(self)

func fadeOut(duration: float = 0.3):
	if has_node("MeshInstance3D"):
		var tween = create_tween()
		tween.tween_property($MeshInstance3D, "transparency", 1.0, duration / 3.0)

	if has_node("TokenMeshInstance3D"):
		var tween = create_tween()
		tween.tween_property($TokenMeshInstance3D, "transparency", 1.0, duration)

	if has_node("ActorOverheadStats"):
		var stats: ActorOverheadStats = $ActorOverheadStats
		stats.fadeOut()
#endregion

#region Repository
class Repository:
	static var All: Implementation = Implementation.new()
	static var Alive: Implementation = Implementation.new()
	static var Hovered: Implementation = Implementation.new()

	class Implementation:
		var List: Array[Actor] = []

		func Register(actor: Actor):
			var index = List.find(actor)
			if index >= 0:
				return
			List.push_back(actor)

		func Unregister(actor: Actor):
			var index = List.find(actor)
			if index < 0:
				return
			List.remove_at(index)
#endregion

#region Enums
enum Faction {
	None = -1,

	Kin = 0,
	Neutral = 1,
	CityThugs = 2,
	Algae = 3,
	Wolfpack = 4,
	PlaceholderFaction2 = 5,
	PlaceholderFaction3 = 6,
	PlaceholderFaction4 = 7,
	PlaceholderFaction5 = 8,
}

static var PlayerFaction = Faction.Kin

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
#endregion

static var SignalBus: SignalBusImplementation = SignalBusImplementation.new()
class SignalBusImplementation extends NodeSignalBus:
	signal ActorDefinitionChanged(actor: Actor)
	signal ActorDestroyed(actor: Actor)
