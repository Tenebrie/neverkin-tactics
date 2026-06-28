@abstract class_name BaseTelegraph
extends Node3D

var Alliance: Actor.Alliance = Actor.Alliance.Neutral:
	set(value):
		Alliance = value
		updateColor()

var cleaningUp: bool = false
var growPercentage: float = 0.0

func _ready() -> void:
	updateColor()

func updateColor() -> void:
	setColor(ActorUtils.GetAllianceColor(Alliance))

@abstract func setColor(_color: Color) -> void
@abstract func cleanUp() -> void
