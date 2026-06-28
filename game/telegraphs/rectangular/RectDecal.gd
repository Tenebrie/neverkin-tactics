class_name RectDecal
extends MeshInstance3D

var fadingIn: bool = true
var fadingOut: bool = false
var fadeValue: float = 0.0
var fadeInDuration: float = 0.25
var fadeOutDuration: float = 0.1
var OnFadeOut: Callable

func _ready() -> void:
	set_instance_shader_parameter(&"FADE", fadeValue)

func _process(delta: float) -> void:
	if fadingOut:
		fadeValue -= float(delta) * (1.0 / fadeOutDuration)
		set_instance_shader_parameter(&"FADE", fadeValue)
		if fadeValue <= 0.0:
			if OnFadeOut.is_valid():
				OnFadeOut.call()
			queue_free()
	elif fadingIn:
		fadeValue += float(delta) * (1.0 / fadeOutDuration)
		set_instance_shader_parameter(&"FADE", fadeValue)
		if fadeValue >= 1.0:
			fadeValue = 1.0
			fadingIn = false

func cleanUp() -> void:
	fadeValue = 1.0
	fadingIn = false
	fadingOut = true
