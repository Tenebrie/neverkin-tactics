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
		fadeValue = clampf(fadeValue, 0.0, 1.0)
		set_instance_shader_parameter(&"FADE", fadeValue)
	elif fadingIn:
		fadeValue += float(delta) * (1.0 / fadeOutDuration)
		set_instance_shader_parameter(&"FADE", fadeValue)
		if fadeValue >= 1.0:
			fadeValue = 1.0
			fadingIn = false

func SetInnerAlpha(value: float) -> void:
	set_instance_shader_parameter(&"INNER_ALPHA", value)

func cleanUp() -> void:
	#fadeValue = 1.0
	fadingIn = false
	fadingOut = true
