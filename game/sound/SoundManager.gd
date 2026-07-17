extends Node
class_name SoundManager

static var Instance: SoundManager:
	get:
		return SoundManagerInstance

func _ready() -> void:
	add_child(Asset.Instantiate(SoundAmbiencePlayer))
