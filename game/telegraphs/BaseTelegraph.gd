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

func onBodyEntered(body: Node3D):
	if body is not Actor:
		return
	var actor = body as Actor
	_targets.append(actor)
	if not TargetValidator.is_valid() or TargetValidator.call(actor):
		TargetEntered.emit(actor)
		TargetsChanged.emit(_targets)

func onBodyExited(body: Node3D):
	if body is not Actor:
		return
	var actor = body as Actor
	if not _targets.has(actor):
		return
	_targets.erase(actor)
	TargetExited.emit(actor)
	TargetsChanged.emit(_targets)

@abstract func setColor(color: Color) -> void
@abstract func cleanUp() -> void
