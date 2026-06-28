extends Component3D
class_name SkillController

var SelectedSkill: Skill = null

signal SelectedSkillChanged(skill: Skill)

func _ready() -> void:
	TurnManager.Instance.CurrentActorChanged.connect(func():
		Select(null)
	)
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
	SelectedSkillChanged.emit(skill)

func Select(skill: Skill) -> void:
	SelectedSkill = skill
	SelectedSkillChanged.emit(skill)
