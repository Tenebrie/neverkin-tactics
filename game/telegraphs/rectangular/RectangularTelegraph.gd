class_name RectangularTelegraph
extends BaseTelegraph

enum Origin {
	CENTER,
	START,
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

var height: float = 2.0:
	set(value):
		height = value
		updateSize()

var lengthOrigin: int = Origin.CENTER:
	set(value):
		lengthOrigin = value
		if value == Origin.START:
			var decalPos = decal.position
			var shapePos = collisionShape.position
			decal.position = Vector3(decalPos.x, decalPos.y, decalPos.z - length / 2.0)
			collisionShape.position = Vector3(shapePos.x, shapePos.y, shapePos.z - length / 2.0)


func _enter_tree() -> void:
	hitbox = get_node("Hitbox") as Area3D
	decal = get_node("RectDecal") as RectDecal
	collisionShape = get_node("Hitbox/CollisionShape3D") as CollisionShape3D
	collisionShape.shape = collisionShape.shape.duplicate() as Shape3D

func _process(_delta: float) -> void:
	decal.set_instance_shader_parameter(&"PROGRESS", growPercentage)

func updateSize() -> void:
	(decal.mesh as PlaneMesh).size = Vector2(32, 32)
	(collisionShape.shape as BoxShape3D).size = Vector3(width, height, length)
	decal.set_instance_shader_parameter(&"SIZE_X", width / 2.0)
	decal.set_instance_shader_parameter(&"SIZE_Z", length / 2.0)

func setColor(color: Color) -> void:
	decal.set_instance_shader_parameter(&"COLOR_R", color.r)
	decal.set_instance_shader_parameter(&"COLOR_G", color.g)
	decal.set_instance_shader_parameter(&"COLOR_B", color.b)

func cleanUp():
	queue_free()
