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
		var telegraph = parent.telegraphs.FindTelegraph(areaTelegraph)
		return _getDrainedActionPoints(actor, telegraph.Targets, telegraph.global_position)

func isCastable() -> Variant:
	if _countAvailableCooldown() == 0:
		return Error.new("No cooldowns to give away")
	return super.isCastable()

func _countAvailableCooldown() -> int:
	var total = 0
	for skill in parent.Skills.activeSkillGroup.GetAll():
		if skill == self:
			continue
		total += skill.cooldownRemaining
	return total

func _getDrainedActionPoints(actor: Actor, targets: Array[Actor], origin: Vector3) -> int:
	return _computeDrainShares(targets, origin).get(actor, 0)

func _computeDrainShares(targets: Array[Actor], origin: Vector3) -> Dictionary[Actor, int]:
	var pool = _countAvailableCooldown()
	var shares: Dictionary[Actor, int] = {}
	var weights: Dictionary[Actor, float] = {}
	for target in targets:
		shares[target] = 0
		var proximity = maxf(TelegraphRadius - ActorUtils.flatDistanceTo(target, origin), 0.01)
		weights[target] = proximity * proximity

	for i in range(pool):
		var best: Actor = null
		var bestScore = 0.0
		for target in targets:
			if shares[target] >= target.actions.ActionPointsAvailable:
				continue
			var score = weights[target] / (shares[target] + 1)
			if best == null or score > bestScore:
				best = target
				bestScore = score
		if best == null:
			break
		shares[best] += 1
	return shares

func _drainCooldown(value: int) -> void:
	for i in range(value):
		for skill in parent.Skills.activeSkillGroup.GetAll():
			if skill == self or skill.cooldownRemaining == 0:
				continue
			skill.cooldownRemaining -= 1
			break

func _cast(targets: TargetData) -> void:
	var pointsToDrain = _computeDrainShares(targets.perTelegraph[areaTelegraph], targets.mousePoint)

	for actor: Actor in pointsToDrain.keys():
		var value = pointsToDrain[actor]
		if value == 0:
			continue
		actor.actions.ConsumeActionPoints(value)
