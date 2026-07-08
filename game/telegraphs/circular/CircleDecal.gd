@tool
class_name CircleDecal
extends MeshInstance3D

var persistent: bool = false:
	set(value):
		persistent = value
		set_instance_shader_parameter(&"PROGRESS", 1.0 if value else 0.5)

@export var Persistent: bool = false:
	set(value):
		persistent = value

var radius: float = 0.5

@export_range(0.25, 10.0) var Radius: float = 0.5:
	set(value):
		radius = value
		(mesh as PlaneMesh).size = Vector2(value * 2.0, value * 2.0)
		set_instance_shader_parameter(&"RADIUS", radius)

var coneAngle: float = 3.15

@export_range(0.0, 3.15) var ConeAngle: float = 3.15:
	set(value):
		coneAngle = value
		set_instance_shader_parameter(&"SECTOR", value)

@export var Faction: int = Actor.Faction.Neutral:
	set(value):
		Faction = value
		SetColor(ActorUtils.getFactionColor(value))

var fadingIn: bool = true
var fadingOut: bool = false
var fadeValue: float = 0.0
var fadeInDuration: float = 0.25
var fadeOutDuration: float = 0.1
var OnFadeOut: Callable

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	set_instance_shader_parameter(&"FADE", fadeValue)

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if fadingOut:
		fadeValue -= float(delta) * (1.0 / fadeOutDuration)
		set_instance_shader_parameter(&"FADE", fadeValue)
		if fadeValue <= 0.0:
			if OnFadeOut.is_valid():
				OnFadeOut.call()
			queue_free()
	elif fadingIn:
		fadeValue += float(delta) * (1.0 / fadeInDuration)
		set_instance_shader_parameter(&"FADE", fadeValue)
		if fadeValue >= 1.0:
			fadeValue = 1.0
			fadingIn = false

func SetInnerAlpha(value: float) -> void:
	set_instance_shader_parameter(&"INNER_ALPHA", value)

func SetProgress(value: float) -> void:
	set_instance_shader_parameter(&"PROGRESS", value)

func SetColor(color: Color) -> void:
	set_instance_shader_parameter(&"COLOR_R", color.r)
	set_instance_shader_parameter(&"COLOR_G", color.g)
	set_instance_shader_parameter(&"COLOR_B", color.b)
	set_instance_shader_parameter(&"COLOR_A", color.a)

func SetOuterWidth(value: float) -> void:
	set_instance_shader_parameter(&"OUTER_WIDTH", value / 20.0)

func cleanUp() -> void:
	fadeValue = 1.0
	fadingIn = false
	fadingOut = true
