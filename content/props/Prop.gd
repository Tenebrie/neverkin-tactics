@tool
extends Actor
class_name Prop

func _ready() -> void:
	Definition = ActorDefinition.new()
	Definition.Alliance = Alliance.Neutral
	super._ready()
