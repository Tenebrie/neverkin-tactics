extends Component
class_name ActorDefaultAction

static func isModifierHeld() -> bool:
	return Input.is_key_pressed(KEY_SHIFT) or Input.is_key_pressed(KEY_CTRL)

func _process(_delta: float) -> void:
	if shouldAutoSelect():
		if parent.Skills.SelectedSkill == null:
			parent.Skills.SelectAuto(parent.Skills.GetByIndex(0))
	elif parent.Skills.IsAutoSelected:
		parent.Skills.Unselect()

func shouldAutoSelect() -> bool:
	if TurnManager.Instance.activeActor != parent or parent.faction != Actor.PlayerFaction:
		return false
	if isModifierHeld():
		return false
	var hovered = Actor.Repository.Hovered.first()
	if hovered == null or hovered.isDead or not ActorUtils.isHostileTo(hovered, parent):
		return false
	if parent.targeting.lockedMode != ActorTargeting.TargetMode.None:
		return false
	if parent.Skills.isAnySkillBeingCast() or parent.actions.IsPerformingAnyAction():
		return false
	return parent.Skills.GetByIndex(0) != null
