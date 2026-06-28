class_name CircularTelegraph
extends BaseTelegraph

var decal: CircleDecal
var hitbox: Area3D
var radius: float = 0.5:
	set(value):
		radius = value
		updateRadius()

func _enter_tree() -> void:
	hitbox = get_node("Hitbox") as Area3D
	decal = get_node("CircleDecal") as CircleDecal

func _process(_delta: float) -> void:
	decal.set_instance_shader_parameter(&"PROGRESS", growPercentage)

func updateRadius() -> void:
	hitbox.scale = Vector3(radius * 2.0, radius * 2.0, radius * 2.0)
	decal.Radius = radius

func setColor(color: Color) -> void:
	decal.set_instance_shader_parameter(&"COLOR_R", color.r)
	decal.set_instance_shader_parameter(&"COLOR_G", color.g)
	decal.set_instance_shader_parameter(&"COLOR_B", color.b)

func cleanUp() -> void:
	decal.cleanUp()
	decal.OnFadeOut = func():
		queue_free()
