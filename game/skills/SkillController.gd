extends Component3D
class_name SkillController

var SelectedSkill: Skill = null

func _ready() -> void:
	for skill in parent.Definition.Skills:
		Add(skill.new())

func Add(ability: Skill) -> void:
	add_child(ability)

func Has(ability: GDScript[Skill]) -> bool:
	for child in get_children():
		if is_instance_of(child, ability):
			return true

	return false

func Count(ability: GDScript[Skill]) -> int:
	var count := 0
	for child in get_children():
		if is_instance_of(child, ability):
			count += 1

	return count

func Get(ability: GDScript[Skill]) -> Skill:
	for child in get_children():
		if is_instance_of(child, ability):
			return child

	return null

func GetByIndex(index: int) -> Skill:
	var childrenSeen = 0
	for child in get_children():
		if is_instance_of(child, Skill):
			if childrenSeen == index:
				return child
			childrenSeen += 1
	return null

func SelectByIndex(index: int) -> void:
	var skill = GetByIndex(index)
	SelectedSkill = skill

func Select(skill: Skill) -> void:
	SelectedSkill = skill

func GetMouseWorldPlanePosition() -> Vector3:
	var camera := get_viewport().get_camera_3d()
	var mouse_pos := get_viewport().get_mouse_position()
	var origin := camera.project_ray_origin(mouse_pos)
	var direction := camera.project_ray_normal(mouse_pos)

	# Intersect with Y=0 plane
	var plane := Plane(Vector3.UP, 0.0)
	var intersection: Vector3 = plane.intersects_ray(origin, direction)

	if intersection:
		return intersection
	return Vector3.ZERO
