@abstract
class_name BeamTelegraph
extends Telegraph

## A cross-section swept along -Z. What the cross-section is decides the volume: a flat slab
## gives a box, a circle gives a stadium.

enum Origin {
	Center,
	Start,
}

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

@abstract func updateSize() -> void
@abstract func updateOrigin() -> void

## World position the swept cross-section's centre reaches at [member length] — where a
## projectile lands, or where a pushed unit comes to rest.
func Endpoint() -> Vector3:
	return global_position + (-global_basis.z) * length

func queryBasis() -> Basis:
	return global_basis.orthonormalized()

func queryOrigin() -> Vector3:
	return Vector3(global_position.x, height / 2.0, global_position.z)

## Colliders in the beam's path at its full untruncated range, sorted near-to-far. This is what
## collision rules search to decide where the beam stops.
@abstract func GatherBeamContacts(mask: int, exclude: Array[RID]) -> Array[RaycastUtils.ShapeContact]

## Distance along the beam at which [param contact] is first entered.
@abstract func DistanceToContact(
	contact: RaycastUtils.ShapeContact,
	allContacts: Array[RaycastUtils.ShapeContact],
	mask: int,
	exclude: Array[RID],
) -> float
