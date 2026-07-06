extends Component
class_name ActorBehaviour

enum ActionVariant {
	Skip,
	MoveTo,
	UseSkill,
	EndTurn,
}

class TurnAction:
	var variant: ActionVariant

	func _init(initVariant: ActionVariant):
		variant = initVariant

	## Skip a single action
	static func Skip():
		return TurnAction.new(ActionVariant.Skip)


	var moveToParams: MoveToParams
	class MoveToParams:
		var point: Vector3

	static func MoveTo(point: Vector3):
		var action = TurnAction.new(ActionVariant.MoveTo)
		action.moveToParams = MoveToParams.new()
		action.moveToParams.point = point
		return action


	var useSkillParams: UseSkillParams
	class UseSkillParams:
		var skill: GDScript[Skill]
		var targetPoint: Vector3

	static func UseSkillOnSelf(skill: GDScript[Skill]):
		var action = TurnAction.new(ActionVariant.UseSkill)
		action.useSkillParams = UseSkillParams.new()
		action.useSkillParams.skill = skill
		return action

	static func UseSkillOnPoint(skill: GDScript[Skill], targetPoint: Vector3):
		var action = TurnAction.new(ActionVariant.UseSkill)
		action.useSkillParams = UseSkillParams.new()
		action.useSkillParams.skill = skill
		action.useSkillParams.targetPoint = targetPoint
		return action

	static func UseSkillOnActor(skill: GDScript[Skill], target: Actor):
		var action = TurnAction.new(ActionVariant.UseSkill)
		action.useSkillParams = UseSkillParams.new()
		action.useSkillParams.skill = skill
		action.useSkillParams.targetPoint = target.global_position
		return action

	## Force end turn without performing any further actions
	static func EndTurn():
		return TurnAction.new(ActionVariant.EndTurn)
