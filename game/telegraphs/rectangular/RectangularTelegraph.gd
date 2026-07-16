class_name RectangularTelegraph
extends Telegraph

enum Origin {
	Center,
	Start,
}

var decal: RectDecal
var hitbox: Area3D
var collisionShape: CollisionShape3D

var queryShape = BoxShape3D.new()
var crossSectionShape = BoxShape3D.new()

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
	(collisionShape.shape as BoxShape3D).size = Vector3(width, height, maxf(length, 0.0))
	decal.set_instance_shader_parameter(&"SIZE_X", width / 2.0)
	decal.set_instance_shader_parameter(&"SIZE_Z", maxf(length, 0.0) / 2.0)

func updateOrigin():
	if not isReady:
		return
	if lengthOrigin == Origin.Start:
		var decalPos = Vector3.ZERO
		var shapePos = Vector3.ZERO
		decal.position = Vector3(decalPos.x, decalPos.y, decalPos.z - length / 2.0)
		collisionShape.position = Vector3(shapePos.x, shapePos.y, shapePos.z - length / 2.0)

#region Collision query
func queryBasis() -> Basis:
	return global_basis.orthonormalized()

func queryOrigin() -> Vector3:
	return Vector3(global_position.x, height / 2.0, global_position.z)

## Colliders overlapping this telegraph at its full untruncated range, sorted near-to-far
## along the beam.
func GatherContacts(mask: int, exclude: Array[RID] = []) -> Array[RaycastUtils.ShapeContact]:
	var basis = queryBasis()
	var origin = queryOrigin()
	var direction = -basis.z
	var fullLength = definition.RectLength
	queryShape.size = Vector3(width, height, fullLength)
	var transform = Transform3D(basis, origin + direction * (fullLength / 2.0))
	var measure = func(pos: Vector3) -> float:
		var offset = pos - origin
		return direction.dot(Vector3(offset.x, 0.0, offset.z))
	return RaycastUtils.GatherContacts(
		get_world_3d().direct_space_state,
		queryShape, transform, measure,
		mask, exclude,
	)

## Distance along this telegraph at which [param contact] is first entered.
func DistanceToContact(
	contact: RaycastUtils.ShapeContact,
	allContacts: Array[RaycastUtils.ShapeContact],
	mask: int,
	exclude: Array[RID] = [],
) -> float:
	var basis = queryBasis()
	var origin = queryOrigin()
	var fullLength = definition.RectLength
	crossSectionShape.size = Vector3(width, height, 0.05)
	return RaycastUtils.ResolveContactDistance(
		get_world_3d().direct_space_state,
		crossSectionShape, Transform3D(basis, origin), -basis.z * fullLength,
		mask, contact.Rid, allContacts, exclude,
	)
#endregion

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
