class_name RaycastUtils

class ShapeContact:
	var Rid: RID
	var Collider: CollisionObject3D
	var Distance: float  # Projected distance of collider center along the sweep axis

	func _init(rid: RID, collider: CollisionObject3D, distance: float):
		Rid = rid
		Collider = collider
		Distance = distance


## Gathers all colliders overlapping a beam volume in a single query, sorted near-to-far
## by the projection of each collider's center onto [param direction]. One query total.
## [param basis] must be orthonormal.
static func GatherBeamContacts(
	spaceState: PhysicsDirectSpaceState3D,
	crossSection: Vector2,
	basis: Basis,
	origin: Vector3,
	direction: Vector3,
	length: float,
	collisionMask: int,
	initialExclude: Array[RID] = [],
	maxResults: int = 120,
) -> Array[ShapeContact]:
	var volume = BoxShape3D.new()
	volume.size = Vector3(crossSection.x, crossSection.y, length)

	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = volume
	query.transform = Transform3D(basis, origin + direction * (length / 2.0))
	query.collision_mask = collisionMask
	query.exclude = initialExclude

	var results = spaceState.intersect_shape(query, maxResults)
	var contacts: Array[ShapeContact] = []
	for result in results:
		var collider = instance_from_id(result["collider_id"]) as CollisionObject3D
		if collider == null:
			continue
		var offset = collider.global_position - origin
		var distance = direction.dot(Vector3(offset.x, 0.0, offset.z))
		contacts.append(ShapeContact.new(result["rid"], collider, distance))

	contacts.sort_custom(func(a: ShapeContact, b: ShapeContact) -> bool: return a.Distance < b.Distance)
	return contacts


## Precise entry distance of [param targetRid] along the beam, via a single cast_motion
## that ignores everything else in [param allContacts].
static func ResolveContactDistance(
	spaceState: PhysicsDirectSpaceState3D,
	shape: Shape3D,
	basis: Basis,
	origin: Vector3,
	direction: Vector3,
	length: float,
	collisionMask: int,
	targetRid: RID,
	allContacts: Array[ShapeContact],
	initialExclude: Array[RID] = [],
) -> float:
	var exclude = initialExclude.duplicate()
	for contact in allContacts:
		if contact.Rid != targetRid:
			exclude.append(contact.Rid)

	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(basis, origin)
	query.collision_mask = collisionMask
	query.exclude = exclude
	query.motion = direction * length

	var fraction = spaceState.cast_motion(query)
	if fraction.is_empty():
		return length
	return fraction[0] * length
