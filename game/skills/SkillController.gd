extends Component3D
class_name SkillController

var SelectedSkill: Skill = null:
	set(v):
		if v == SelectedSkill:
			return
		var previous = SelectedSkill
		SelectedSkill = v
		SelectedSkillChanged.emit(v, previous)

@onready var commonSkillGroup: ControlGroup = ControlGroup.new()
@onready var activeSkillGroup: ControlGroup = ControlGroup.new()
@onready var inactiveSkillGroup: ControlGroup = ControlGroup.new()

signal SkillsChanged
signal SelectedSkillChanged(current: Skill, previous: Skill)

func _parentReady() -> void:
	add_child(commonSkillGroup)
	add_child(activeSkillGroup)
	add_child(inactiveSkillGroup)
	TurnManager.Instance.CurrentActorChanged.connect(func():
		Select(null)
	)

	LoadCommonSkills()
	LoadSkills()
	parent.DefinitionChanged.connect(func():
		LoadSkills()
	)
	parent.actions.ActionPointsChanged.connect(func(current):
		if SelectedSkill != null and SelectedSkill.ActionPointCost > current:
			Select(null)
	)

func LoadCommonSkills() -> void:
	commonSkillGroup.Add(SkillMove.new())

func LoadSkills() -> void:
	for skillOrNode in activeSkillGroup.get_children():
		if skillOrNode is Skill:
			Deactivate(skillOrNode)
		else:
			skillOrNode.queue_free()
			activeSkillGroup.remove_child(skillOrNode)

	for skillScript in parent.Definition.Skills:
		if skillScript == null:
			activeSkillGroup.add_child(Node3D.new())
			continue
		if inactiveSkillGroup.Has(skillScript):
			Activate(inactiveSkillGroup.Get(skillScript))
			continue
		Add(skillScript.new())
	SkillsChanged.emit()

func Add(ability: Skill) -> void:
	return activeSkillGroup.Add(ability)

func Has(ability: GDScript[Skill]) -> bool:
	return activeSkillGroup.Has(ability)

func Count(ability: GDScript[Skill]) -> int:
	return activeSkillGroup.Count(ability)

func Get(ability: GDScript[Skill]) -> Skill:
	return activeSkillGroup.Get(ability)

func GetByIndex(index: int) -> Skill:
	return activeSkillGroup.GetByIndex(index)

func Activate(skill: Skill) -> bool:
	if skill.ControlGroup != inactiveSkillGroup:
		return false
	inactiveSkillGroup.remove_child(skill)
	activeSkillGroup.add_child(skill)
	return true

func Deactivate(skill: Skill) -> bool:
	if skill.ControlGroup != activeSkillGroup:
		return false
	if skill != null and skill == SelectedSkill:
		Select(null)
	activeSkillGroup.remove_child(skill)
	inactiveSkillGroup.add_child(skill)
	return true

func SelectByIndex(index: int) -> void:
	var skill = GetByIndex(index)
	SelectedSkill = skill

func Select(skill: Skill) -> void:
	SelectedSkill = skill

class ControlGroup extends Node3D:
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
