class_name CapsuleTelegraph
extends BeamTelegraph

var decal: CapsuleDecal
var hitbox: Area3D

var sweepShape = CylinderShape3D.new()
var candidateShape = BoxShape3D.new()

func _enter_tree():
	hitbox = get_node("Hitbox") as Area3D
	decal = get_node("CapsuleDecal") as CapsuleDecal
	hitbox.monitoring = false

func _ready():
	super._ready()
	updateSize()
	updateOrigin()

func _process(_delta: float):
	decal.set_instance_shader_parameter(&"PROGRESS", growPercentage)

func radius() -> float:
	return width / 2.0

func updateSize():
	if not isReady:
		return
	(decal.mesh as PlaneMesh).size = Vector2(width, maxf(length, 0.0) + width)
	sweepShape.radius = radius()
	sweepShape.height = height
	decal.set_instance_shader_parameter(&"RADIUS", radius())
	decal.set_instance_shader_parameter(&"HALF_TRAVEL", maxf(length, 0.0) / 2.0)

func updateOrigin():
	if not isReady:
		return
	if lengthOrigin == Origin.Start:
		decal.position = Vector3(0, 0, -length / 2.0)

#region Collision query
## Every collider the swept circle actually reaches within [param travel], sorted near-to-far,
## with Distance set to the exact travel at which the circle first touches it. The box is only
## a candidate filter — anything it catches that the circle never touches is dropped here.
func gatherSwept(travel: float, mask: int, exclude: Array[RID]) -> Array[RaycastUtils.ShapeContact]:
	var basis = queryBasis()
	var origin = queryOrigin()
	var direction = -basis.z
	var spaceState = get_world_3d().direct_space_state

	candidateShape.size = Vector3(width, height, travel + width)
	var measure = func(pos: Vector3) -> float:
		var offset = pos - origin
		return direction.dot(Vector3(offset.x, 0.0, offset.z))

	var candidates = RaycastUtils.GatherContacts(
		spaceState,
		candidateShape,
		Transform3D(basis, origin + direction * (travel / 2.0)),
		measure, mask, exclude,
	)

	var reached: Array[RaycastUtils.ShapeContact] = []
	for candidate in candidates:
		var distance = RaycastUtils.ResolveContactDistance(
			spaceState, sweepShape, Transform3D(basis, origin), direction * travel,
			mask, candidate.Rid, candidates, exclude,
		)
		if distance >= travel:
			continue
		reached.push_back(RaycastUtils.ShapeContact.new(candidate.Rid, candidate.Collider, distance))

	reached.sort_custom(func(a: RaycastUtils.ShapeContact, b: RaycastUtils.ShapeContact) -> bool:
		return a.Distance < b.Distance
	)
	return reached

func GatherContacts(mask: int, exclude: Array[RID] = []) -> Array[RaycastUtils.ShapeContact]:
	return gatherSwept(maxf(length, 0.0), mask, exclude)

## Colliders in the circle's path at its full untruncated travel. What collision rules search
## to decide where the circle stops.
func GatherBeamContacts(mask: int, exclude: Array[RID] = []) -> Array[RaycastUtils.ShapeContact]:
	return gatherSwept(definition.RectLength, mask, exclude)

## [member RaycastUtils.ShapeContact.Distance] is already the exact sweep distance.
func DistanceToContact(
	contact: RaycastUtils.ShapeContact,
	_allContacts: Array[RaycastUtils.ShapeContact],
	_mask: int,
	_exclude: Array[RID] = [],
) -> float:
	return contact.Distance
#endregion

func pollTargets():
	_targets = []
	for contact in GatherContacts(hitbox.collision_mask):
		if contact.Collider is Actor:
			_targets.push_back(contact.Collider as Actor)
	checkTargetsDiff()

func setColor(color: Color):
	decal.set_instance_shader_parameter(&"COLOR_R", color.r)
	decal.set_instance_shader_parameter(&"COLOR_G", color.g)
	decal.set_instance_shader_parameter(&"COLOR_B", color.b)
	decal.set_instance_shader_parameter(&"COLOR_A", color.a)

func cleanUp():
	super.cleanUp()
	decal.cleanUp()

func IsPathable(agentSize: float) -> bool:
	var sampleCount = 24
	var map = get_world_3d().navigation_map

	var originOffsetZ = 0.0
	if lengthOrigin == Origin.Start:
		originOffsetZ = -length / 2.0

	var halfTravel = maxf(length, 0.0) / 2.0
	for i in sampleCount:
		var t = (float(i) / (sampleCount - 1)) * 2.0 - 1.0
		var localPoint = Vector3(0, 0, originOffsetZ + t * halfTravel)
		var worldPoint = global_transform * localPoint
		if not isPointOnNavmesh(map, worldPoint, agentSize):
			return false
	return true
