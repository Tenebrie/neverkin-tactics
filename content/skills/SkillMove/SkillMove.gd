extends Skill
class_name SkillMove

func _ready() -> void:
	Definition = preload("res://content/skills/SkillMove/SkillMove.tres").duplicate()

	afterCast.connect(func():
		Parent.Skills.Select(null)
		Parent.targeting.lockedMode = ActorTargeting.TargetMode.None
	)

	Controller.SelectedSkillChanged.connect(func(_c, previous):
		if previous == self:
			Parent.targeting.lockedMode = ActorTargeting.TargetMode.None
	)

	super._ready()

func _cast(_targets: TargetData) -> void:
	var path = Parent.targeting.getLegalPathToMouse()
	if path.size() == 0:
		return
	Parent.actions.IssueOrder_MoveThroughPath(path)
