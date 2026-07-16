class_name RaycastUtils

class ShapeContact:
	var Rid: RID
	var Collider: CollisionObject3D
	var Distance: float  # Projected distance of collider center along the sweep axis

	func _init(rid: RID, collider: CollisionObject3D, distance: float):
		Rid = rid
		Collider = collider
		Distance = distance


## Gathers all colliders overlapping [param shape] placed at [param transform] in a single
## query, sorted near-to-far by [param measure], which maps a collider's global position to
## the distance recorded on its [ShapeContact].
static func GatherContacts(
	spaceState: PhysicsDirectSpaceState3D,
	shape: Shape3D,
	transform: Transform3D,
	measure: func(Vector3) -> float,
	collisionMask: int,
	exclude: Array[RID] = [],
	maxResults: int = 120,
) -> Array[ShapeContact]:
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = transform
	query.collision_mask = collisionMask
	query.exclude = exclude

	var results = spaceState.intersect_shape(query, maxResults)
	var contacts: Array[ShapeContact] = []
	for result in results:
		var collider = instance_from_id(result["collider_id"]) as CollisionObject3D
		if collider == null:
			continue
		contacts.append(ShapeContact.new(result["rid"], collider, measure.call(collider.global_position)))

	contacts.sort_custom(func(a: ShapeContact, b: ShapeContact) -> bool: return a.Distance < b.Distance)
	return contacts


## Precise entry distance of [param targetRid] along [param motion], via a single cast_motion
## that ignores everything else in [param allContacts].
static func ResolveContactDistance(
	spaceState: PhysicsDirectSpaceState3D,
	shape: Shape3D,
	transform: Transform3D,
	motion: Vector3,
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
	query.transform = transform
	query.collision_mask = collisionMask
	query.exclude = exclude
	query.motion = motion

	var length = motion.length()
	var fraction = spaceState.cast_motion(query)
	if fraction.is_empty():
		return length
	return fraction[0] * length
