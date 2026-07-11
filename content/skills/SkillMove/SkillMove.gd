extends Skill
class_name SkillMove

func _ready() -> void:
	definition = preload("res://content/skills/SkillMove/SkillMove.tres").duplicate()

	afterCast.connect(func():
		parent.Skills.Select(null)
		parent.targeting.lockedMode = ActorTargeting.TargetMode.None
	)

	Controller.SelectedSkillChanged.connect(func(_c, previous):
		if previous == self:
			parent.targeting.lockedMode = ActorTargeting.TargetMode.None
	)

	super._ready()

func _cast(_targets: TargetData) -> void:
	var path = parent.targeting.getLegalPathToMouse()
	if path.size() == 0:
		return
	parent.actions.IssueOrder_MoveThroughPath(path)
