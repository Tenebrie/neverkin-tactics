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
	hitbox.monitoring = false

func _ready() -> void:
	super._ready()
	updateRadius()

func _process(_delta: float):
	if IsLeaving:
		return
	decal.set_instance_shader_parameter(&"PROGRESS", growPercentage)

func pollTargets():
	_targets = []
	for contact in GatherContacts(hitbox.collision_mask):
		if contact.Collider is Actor:
			_targets.push_back(contact.Collider as Actor)
	checkTargetsDiff()

func updateRadius():
	if not isReady:
		return
	hitboxShape.shape.radius = radius
	decal.Radius = radius

#region Collision query
## Colliders overlapping this telegraph's radius, sorted near-to-far from its center.
func GatherContacts(mask: int, exclude: Array[RID] = []) -> Array[RaycastUtils.ShapeContact]:
	var center = global_position
	var measure = func(pos: Vector3) -> float:
		var offset = pos - center
		return Vector3(offset.x, 0.0, offset.z).length()
	return RaycastUtils.GatherContacts(
		get_world_3d().direct_space_state,
		hitboxShape.shape, hitboxShape.global_transform, measure,
		mask, exclude,
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

## TODO: Rewrite this
## 1. As navmesh changes during shapeshift, the isPointOnNavmesh may return true, but the post-rebuild navmesh does not agree
## 2. Currently navmesh is generated assuming the agent is a square, so the corners around obstacles are problematic
func IsPathable(_agentSize: float) -> bool:
	var map = get_world_3d().navigation_map
	var center = global_position
	var tolerance = 0.01
	var requiredSize = radius + tolerance
	var currentSize = 0.4
	if NavmeshManager.Instance.currentMapActor:
		currentSize = NavmeshManager.Instance.currentMapActor.physicalSize
	var delta = requiredSize - currentSize

	if not isPointOnNavmesh(map, center, tolerance + maxf(-delta, 0.0)):
		return false

	if delta <= tolerance:
		return true

	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = hitboxShape.shape
	query.transform = hitboxShape.global_transform
	query.collision_mask = CollisionLayer.ACTOR | CollisionLayer.OBSTACLE | CollisionLayer.FULL_COVER | CollisionLayer.HIGH_COVER | CollisionLayer.LOW_COVER
	if NavmeshManager.Instance.currentMapActor:
		query.exclude = [NavmeshManager.Instance.currentMapActor]
	return get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()
