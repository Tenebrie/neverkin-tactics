extends Skill
class_name SkillDebtOfTime

var areaTelegraph = TelegraphPreset.PointArea.new(TelegraphRadius) as TelegraphPreset.PointArea

const TelegraphRadius = 2.0

func _prepare() -> void:
	definition.telegraphs = [
		areaTelegraph,
		TelegraphPreset.MaxCastRange.new(),
	]
	areaTelegraph.addTargetFilter(func(actor: Actor) -> bool:
		return actor is not Prop and ActorUtils.isHostileTo(actor, parent)
	)
	areaTelegraph.ActionPointThreatSelector = func(actor: Actor) -> int:
		var total = _countAvailableCooldown()
		var telegraph = parent.telegraphs.FindTelegraph(areaTelegraph)
		var index = _getActorIndex(actor, telegraph.Targets, telegraph.global_position)
		print("Index is ", index)

		return 1

func _countAvailableCooldown() -> int:
	var total = 0
	for skill in parent.Skills.activeSkillGroup.GetAll():
		if skill == self:
			continue
		total += skill.cooldownRemaining
	return total

func _getActorIndex(actor: Actor, targets: Array[Actor], origin: Vector3) -> int:
	var sortedTargets = targets.slice(0)
	sortedTargets.sort_custom(func(a, b):
		return ActorUtils.flatDistanceTo(a, origin) < ActorUtils.flatDistanceTo(b, origin)
	)
	return sortedTargets.find(actor)
