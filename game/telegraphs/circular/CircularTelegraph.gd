class_name CircularTelegraph
extends Telegraph

var decal: CircleDecal
var hitbox: Area3D
var hitboxShape: CollisionShape3D

var radius: float = 0.5:
	set(value):
		radius = value
		updateRadius()

func _enter_tree():
	hitbox = get_node("Hitbox") as Area3D
	hitboxShape = get_node("Hitbox/CollisionShape3D")
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
	hitboxShape.shape.radius = radius
	decal.Radius = radius

func setColor(color: Color):
	decal.set_instance_shader_parameter(&"COLOR_R", color.r)
	decal.set_instance_shader_parameter(&"COLOR_G", color.g)
	decal.set_instance_shader_parameter(&"COLOR_B", color.b)
	decal.set_instance_shader_parameter(&"COLOR_A", color.a)

func cleanUp():
	decal.cleanUp()
	decal.OnFadeOut = func():
		queue_free()
	super.cleanUp()

## TODO: Check collision properly
func IsPathable() -> bool:
	var sampleCount = 32
	var map = get_world_3d().navigation_map
	var center = global_position

	# Check center
	if not isPointOnNavmesh(map, center):
		return false

	# Check ring of points at the edge
	for i in sampleCount:
		var angle = (TAU / sampleCount) * i
		var offset = Vector3(cos(angle), 0, sin(angle)) * radius
		var point = center + offset
		if not isPointOnNavmesh(map, point):
			return false
	return true
