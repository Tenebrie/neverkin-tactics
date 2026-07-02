@abstract
class_name Telegraph
extends Node3D

@onready var isReady: bool = true

signal TargetEntered(target: Actor)
signal TargetExited(target: Actor)
signal TargetsChanged(targets: Array[Actor])

var ParentSkill: Skill
var Definition: TelegraphDefinition

var Tint: Color = Color.GRAY:
	set(value):
		Tint = value
		if isReady:
			setColor(value)

var GeneralValidator: Callable
var TargetValidator: Callable

var growPercentage: float = 0.0
var _targets: Array[Actor] = []
## Both general and per-target validation
var Targets: Array[Actor]
## Per-target validation only
var FilteredOnlyTargets: Array[Actor]

func _ready():
	setColor(Tint)
	set_notify_transform(true)

func _physics_process(_d: float) -> void:
	checkTargetsDiff()

func checkTargetsDiff() -> void:
	refreshFilteredTargets()
	var current = Targets
	for target in current:
		if not previousSeenTargets.has(target):
			TargetEntered.emit(target)
	for target in previousSeenTargets:
		if not current.has(target):
			TargetExited.emit(target)
	if current != previousSeenTargets:
		TargetsChanged.emit(current)
	previousSeenTargets = current

var previousSeenTargets: Array[Actor] = []

func refreshFilteredTargets():
	var result: Array[Actor] = []
	for target in _targets:
		if target != null and is_instance_valid(target):
			if not TargetValidator.is_valid() or TargetValidator.call(target):
				if not result.has(target):
					result.append(target)
	FilteredOnlyTargets = result
	if GeneralValidator != null and GeneralValidator.call() == true:
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
@abstract func IsPathable() -> bool

var IsLeaving = false
func cleanUp() -> void:
	IsLeaving = true

func isPointOnNavmesh(map: RID, point: Vector3, threshold: float = 0.01) -> bool:
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
