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
	if IsLeaving:
		return
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
