extends Skill
class_name SkillStealTime

var targetTelegraph: TelegraphDefinition

func _prepare() -> void:
	targetTelegraph = TelegraphPreset.SingleActor.new()
	.addTargetFilter(func(actor):
		return actor != parent and actor is not Prop and ActorUtils.isAlliedTo(actor, parent)
	)
	.addValidator(func(telegraph: Telegraph):
		var targets = telegraph.FilteredOnlyTargets
		if targets.is_empty():
			return true

		var actorCooldowns = 0
		for skill in targets[0].Skills.activeSkillGroup.GetAll():
			actorCooldowns += skill.cooldownRemaining
		if actorCooldowns == 0:
			return Error.new("Target has no cooldowns to take")
		return true
	)
	definition.telegraphs = [
		TelegraphPreset.MaxCastRange.new(),
		targetTelegraph
	]

func _cast(targets: TargetData) -> void:
	var cooldownsStolen = 0
	for skill in targets.actor.Skills.activeSkillGroup.GetAll():
		cooldownsStolen += skill.cooldownRemaining
		skill.cooldownRemaining = 0
	if cooldownsStolen == 0:
		return

	cooldownRemaining += cooldownsStolen - 1
