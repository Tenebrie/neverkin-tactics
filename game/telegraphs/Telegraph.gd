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

@export var Tint: Color = Color.GRAY:
	set(value):
		Tint = value
		if isReady:
			setColor(value)

@export var GeneralValidator: Callable
@export var TargetValidator: Callable
@export var IgnoredObstacleGroups: Array[StringName]

var growPercentage: float = 0.0
var _targets: Array[Actor] = []
## Both general and per-target validation
var Targets: Array[Actor]
## Per-target validation only
var FilteredOnlyTargets: Array[Actor]

func _ready():
	setColor(Tint)
	definition.created.emit(self)

func _physics_process(_d: float) -> void:
	checkTargetsDiff()

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

func onBodyEntered(body: Node3D):
	if body is not Actor:
		return
	var actor = body as Actor
	_targets.append(actor)
	checkTargetsDiff()

func onBodyExited(body: Node3D):
	if body is not Actor:
		return
	var actor = body as Actor
	if _targets.has(actor):
		_targets.erase(actor)
		checkTargetsDiff()

@abstract func setColor(color: Color) -> void
@abstract func IsPathable(agentSize: float) -> bool

## Colliders overlapping this telegraph's query volume, sorted near-to-far. What "far" means
## is per-shape: distance along the beam for a rect, distance from the center for a circle.
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
}

enum Attachment {
	None,
	Mouse,
	Caster,
}
