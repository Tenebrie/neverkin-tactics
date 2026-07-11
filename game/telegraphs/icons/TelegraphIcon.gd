extends MeshInstance3D
class_name TelegraphIcon

@onready var parent: Telegraph = get_parent()

func SetIcon(icon: Texture2D):
	var material = get_surface_override_material(0) as StandardMaterial3D
	material.albedo_texture = icon

func SetSize(size: Vector2):
	scale = Vector3(size.x, size.y, 1)

func SetTint(tint: Color):
	var material = get_surface_override_material(0) as StandardMaterial3D
	if material.albedo_color != tint:
		material.albedo_color = tint

func _process(_d):
	SetTint(parent.Tint)
