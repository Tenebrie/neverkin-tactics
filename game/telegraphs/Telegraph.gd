@abstract
class_name Telegraph
extends Node3D

@onready var isReady: bool = true

signal TargetEntered(target: Actor)
signal TargetExited(target: Actor)
signal TargetsChanged(targets: Array[Actor])

var ParentSkill: Skill
var definition: TelegraphDefinition

var childText: TelegraphText
var childIcon: TelegraphIcon

## Tint applied to the telegraph and all children
@export var Tint: Color = Color.GRAY:
	set(value):
		Tint = value
		if isReady:
			setColor(Tint * SelfTint)

## Tint applied to telegraph only
@export var SelfTint: Color = Color.WHITE:
	set(value):
		SelfTint = value
		if isReady:
			setColor(Tint * SelfTint)

@export var GeneralValidator: Callable
@export var TargetValidator: Callable
@export var IgnoredObstacleGroups: Array[StringName]

var growPercentage: float = 0.0:
	set(value):
		if value == growPercentage:
			return
		growPercentage = value
		if isReady:
			applyGrowth()
var _targets: Array[Actor] = []
var FirstTarget: Actor:
	get:
		if Targets.is_empty():
			return null
		return Targets[0]
## Both general and per-target validation
var Targets: Array[Actor]
## Per-target validation only
var FilteredOnlyTargets: Array[Actor]

var TargetIcons: Dictionary[Actor, TelegraphIcon]

func _ready():
	setColor(Tint)
	applyGrowth()
	definition.created.emit(self)

@abstract func pollTargets() -> void

func checkTargetsDiff() -> void:
	refreshFilteredTargets()
	var current = Targets
	for target in current:
		if not previousSeenTargets.has(target):
			TargetEntered.emit(target)
			BuffHealthThreat.AddToActor(target, definition.HealthThreatSelector.call(target), self)
			BuffHealthPromise.AddToActor(target, definition.HealthPromiseSelector.call(target), self)
			BuffManaThreat.AddToActor(target, definition.ManaThreatSelector.call(target), self)
			BuffManaPromise.AddToActor(target, definition.ManaPromiseSelector.call(target), self)
			BuffActionPointThreat.AddToActor(target, definition.ActionPointThreatSelector.call(target), self)
			BuffActionPointPromise.AddToActor(target, definition.ActionPointPromiseSelector.call(target), self)
			if definition.IconPerTarget:
				TargetIcons[target] = Asset.Instantiate(TelegraphIcon)
				add_child(TargetIcons[target])
				TargetIcons[target].SetIcon(definition.IconPerTarget)
				TargetIcons[target].SetSize(Vector2(0.75, 0.75))
				TargetIcons[target].SetTint(Tint)
				TargetIcons[target].followTarget = target
				TargetIcons[target].global_position = target.global_position
				TargetIcons[target].global_position.y = RenderHeight.AboveWalls
		else:
			BuffHealthThreat.EnsureIntensity(target, definition.HealthThreatSelector.call(target), self)
			BuffHealthPromise.EnsureIntensity(target, definition.HealthPromiseSelector.call(target), self)
			BuffManaThreat.EnsureIntensity(target, definition.ManaThreatSelector.call(target), self)
			BuffManaPromise.EnsureIntensity(target, definition.ManaPromiseSelector.call(target), self)
			BuffActionPointThreat.EnsureIntensity(target, definition.ActionPointThreatSelector.call(target), self)
			BuffActionPointPromise.EnsureIntensity(target, definition.ActionPointPromiseSelector.call(target), self)
	for target in previousSeenTargets:
		if not current.has(target):
			TargetExited.emit(target)
			BuffHealthThreat.RemoveByOwner(target, self)
			BuffHealthPromise.RemoveByOwner(target, self)
			BuffManaThreat.RemoveByOwner(target, self)
			BuffManaPromise.RemoveByOwner(target, self)
			BuffActionPointThreat.RemoveByOwner(target, self)
			BuffActionPointPromise.RemoveByOwner(target, self)
			if TargetIcons.has(target):
				TargetIcons[target].queue_free()
				TargetIcons.erase(target)

	if current != previousSeenTargets:
		TargetsChanged.emit(current)
		definition.targetsChanged.emit(current)
	previousSeenTargets = current

var previousSeenTargets: Array[Actor] = []

func refreshFilteredTargets():
	var result: Array[Actor] = []
	for target in _targets:
		if target != null and is_instance_valid(target):
			if not TargetValidator or TargetValidator.call(target):
				if not result.has(target):
					result.append(target)
	FilteredOnlyTargets = result
	if not GeneralValidator or GeneralValidator.call() == true:
		Targets = FilteredOnlyTargets
	else:
		Targets = []

@abstract func setColor(color: Color) -> void
@abstract func applyGrowth() -> void
@abstract func IsPathable(agentSize: float) -> bool
@abstract func GatherContacts(mask: int, exclude: Array[RID] = []) -> Array[RaycastUtils.ShapeContact]

signal cleaningStarted

var IsLeaving = false
func cleanUp() -> void:
	IsLeaving = true
	cleaningStarted.emit()
	checkTargetsDiff()
	await get_tree().create_timer(1.0).timeout
	queue_free()

func isPointOnNavmesh(map: RID, point: Vector3, threshold: float) -> bool:
	var flattenedPoint = Vector3(point.x, RenderHeight.Navigation, point.z)
	var closest = NavigationServer3D.map_get_closest_point(map, flattenedPoint)
	return flattenedPoint.distance_to(closest) < threshold

enum Shape {
	Circle,
	Rect,
	Capsule,
}

enum Attachment {
	None,
	Mouse,
	Caster,
}
