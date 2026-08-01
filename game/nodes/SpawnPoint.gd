@tool
extends Node3D
class_name SpawnPoint

func _ready() -> void:
	if Engine.is_editor_hint():
		add_child(preload("./SpawnPointContent.tscn").instantiate())

func spawn(actorScene: PackedScene):
	var actor = actorScene.instantiate() as Actor
	Game.Scene.add_child.call_deferred(actor)
	#await get_tree().process_frame
	actor.position = ActorUtils.flatPositionOf(self)
	Game.Scene.add_child(actor)
