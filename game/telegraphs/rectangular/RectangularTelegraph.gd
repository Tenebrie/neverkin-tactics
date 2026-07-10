class_name RectangularTelegraph
extends Telegraph

enum Origin {
	Center,
	Start,
}

var decal: RectDecal
var hitbox: Area3D
var collisionShape: CollisionShape3D

var width: float = 1.0:
	set(value):
		width = value
		updateSize()

var length: float = 1.0:
	set(value):
		length = value
		updateSize()
		updateOrigin()

var height: float = 5.0:
	set(value):
		height = value
		updateSize()

var lengthOrigin: Origin = Origin.Center:
	set(value):
		lengthOrigin = value
		updateOrigin()

func _enter_tree():
	hitbox = get_node("Hitbox") as Area3D
	decal = get_node("RectDecal") as RectDecal
	collisionShape = get_node("Hitbox/CollisionShape3D") as CollisionShape3D
	collisionShape.shape = collisionShape.shape.duplicate() as Shape3D

	hitbox.body_entered.connect(onBodyEntered)
	hitbox.body_exited.connect(onBodyExited)

func _exit_tree():
	hitbox.body_entered.disconnect(onBodyEntered)
	hitbox.body_exited.disconnect(onBodyExited)

func _ready():
	super._ready()
	updateSize()
	updateOrigin()

func _process(_delta: float):
	decal.set_instance_shader_parameter(&"PROGRESS", growPercentage)

func updateSize():
	if not isReady:
		return
	(decal.mesh as PlaneMesh).size = Vector2(32, 32)
	(collisionShape.shape as BoxShape3D).size = Vector3(width, height, length)
	decal.set_instance_shader_parameter(&"SIZE_X", width / 2.0)
	decal.set_instance_shader_parameter(&"SIZE_Z", length / 2.0)

func updateOrigin():
	if not isReady:
		return
	if lengthOrigin == Origin.Start:
		var decalPos = Vector3.ZERO
		var shapePos = Vector3.ZERO
		decal.position = Vector3(decalPos.x, decalPos.y, decalPos.z - length / 2.0)
		collisionShape.position = Vector3(shapePos.x, shapePos.y, shapePos.z - length / 2.0)

func setColor(color: Color):
	decal.set_instance_shader_parameter(&"COLOR_R", color.r)
	decal.set_instance_shader_parameter(&"COLOR_G", color.g)
	decal.set_instance_shader_parameter(&"COLOR_B", color.b)
	decal.set_instance_shader_parameter(&"COLOR_A", color.a)

func cleanUp():
	super.cleanUp()
	decal.cleanUp()

func EnableCulling():
	decal.EnableCulling()

## TODO: Check collision properly
func IsPathable(agentSize: float) -> bool:
	var sampleCountX = 16
	var sampleCountZ = 16
	var map = get_world_3d().navigation_map

	var originOffsetZ = 0.0
	if lengthOrigin == Origin.Start:
		originOffsetZ = -length / 2.0

	var halfWidth = width / 2.0
	var halfLength = length / 2.0
	var localCenter = Vector3(0, 0, originOffsetZ)

	for xi in sampleCountX:
		for zi in sampleCountZ:
			var tx = (float(xi) / (sampleCountX - 1)) * 2.0 - 1.0
			var tz = (float(zi) / (sampleCountZ - 1)) * 2.0 - 1.0
			var localPoint = localCenter + Vector3(tx * halfWidth, 0, tz * halfLength)
			var worldPoint = global_transform * localPoint
			if not isPointOnNavmesh(map, worldPoint, agentSize):
				return false
	return true
