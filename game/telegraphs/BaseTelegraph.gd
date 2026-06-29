@abstract
class_name BaseTelegraph
extends Node3D

@onready var isReady: bool = true

signal TargetEntered(target: Actor)
signal TargetExited(target: Actor)
signal TargetsChanged(targets: Array[Actor])

var Tint: Color = Color.GRAY:
	set(value):
		Tint = value
		if isReady:
			setColor(value)

var TargetValidator: Callable

var growPercentage: float = 0.0
var _targets: Array[Actor] = []
var Targets: Array[Actor]:
	get:
		var result: Array[Actor] = []
		for target in _targets:
			if target != null and is_instance_valid(target):
				if not TargetValidator.is_valid() or TargetValidator.call(target):
					if not result.has(target):
						result.append(target)
		return result

func _ready():
	setColor(Tint)
	set_notify_transform(true)

func _physics_process(_d: float) -> void:
	checkTargetsDiff()

func checkTargetsDiff() -> void:
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
@abstract func cleanUp() -> void
@abstract func isPathable() -> bool
