class_name CircularTelegraph
extends BaseTelegraph

var decal: CircleDecal
var hitbox: Area3D

var radius: float = 0.5:
	set(value):
		radius = value
		updateRadius()

func _enter_tree():
	hitbox = get_node("Hitbox") as Area3D
	decal = get_node("CircleDecal") as CircleDecal

	hitbox.body_entered.connect(onBodyEntered)
	hitbox.body_exited.connect(onBodyExited)

func _exit_tree():
	hitbox.body_entered.disconnect(onBodyEntered)
	hitbox.body_exited.disconnect(onBodyExited)

func _ready() -> void:
	super._ready()
	updateRadius()

func _process(_delta: float):
	decal.set_instance_shader_parameter(&"PROGRESS", growPercentage)

func updateRadius():
	if not isReady:
		return
	hitbox.scale = Vector3(radius * 2.0, radius * 2.0, radius * 2.0)
	decal.Radius = radius

func setColor(color: Color):
	decal.set_instance_shader_parameter(&"COLOR_R", color.r)
	decal.set_instance_shader_parameter(&"COLOR_G", color.g)
	decal.set_instance_shader_parameter(&"COLOR_B", color.b)

func cleanUp():
	decal.cleanUp()
	decal.OnFadeOut = func():
		queue_free()
