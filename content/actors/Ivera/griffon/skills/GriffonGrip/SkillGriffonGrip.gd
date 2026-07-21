extends Skill
class_name SkillGriffonGrip

const SlamDamage = 3

var targetTelegraph = TelegraphPreset.SingleActor.new()
var landingTelegraph = TelegraphPreset.PointArea.new(0.0)

func _prepare() -> void:
	targetTelegraph.addTargetFilter(func(actor):
		return actor != parent
	)
	targetTelegraph.HealthThreatSelector = func(actor):
		if landingTelegraph.DisabledSelector.call():
			return 0
		return SlamDamage if landingTelegraph.getInstance().IsPathable(actor.physicalSize) else 0

	landingTelegraph.Attachment = Telegraph.Attachment.None
	landingTelegraph.DisabledSelector = func():
		return targetTelegraph.getInstance().FirstTarget == null
	landingTelegraph.PostProcessors = []
	landingTelegraph.addProcessor(func(telegraph: CircularTelegraph):
		var victim = targetTelegraph.getInstance().FirstTarget
		var parentPosition = ActorUtils.flatPositionOf(parent)
		var victimPosition = ActorUtils.flatPositionOf(victim)
		var jumpVector = (parentPosition - victimPosition).normalized()
		var landingSpot = parentPosition + jumpVector * (parent.physicalSize + 0.1 + victim.physicalSize)
		landingSpot.y = RenderHeight.TelegraphBase
		telegraph.global_position = landingSpot
		telegraph.radius = victim.physicalSize
		landingTelegraph.CircleRadius = victim.physicalSize

		if telegraph.IsPathable(victim.physicalSize):
			telegraph.Tint = TelegraphColor.ExclusionGood
		else:
			telegraph.Tint = TelegraphColor.ExclusionOccupied
	)
	landingTelegraph.Validators = []
	landingTelegraph.addValidator(func(telegraph):
		var victim = targetTelegraph.getInstance().FirstTarget
		if not victim:
			return false
		if not telegraph.IsPathable(victim.physicalSize):
			return Error.new("Not enough free space at destination")
		return true
	)

	definition.telegraphs = [
		TelegraphPreset.MaxCastRange.new(),
		targetTelegraph,
		landingTelegraph,
	]

func _cast(targets: Skill.TargetData) -> void:
	for actorWithBuff in parent.query.allLivingAgents.inRange(2.0).withBuff(SkillGriffonGripBuff).collect():
		actorWithBuff.buffs?.RemoveAll(SkillGriffonGripBuff)

	if not targets.actor.buffs.Has(SkillGriffonGripBuff):
		var buff = SkillGriffonGripBuff.new()
		buff.Owner = parent
		targets.actor.buffs.Add(buff)
		await get_tree().create_timer(0.25).timeout

	await SkillUtils.forceMoveTo(
		targets.actor,
		destination: targets.pointPerTelegraph[landingTelegraph],
		speed: 10.0,
		speedPattern: SkillUtils.MoveSpeed.Accelerating
	)
	targets.actor.stats.dealSkillDamage(targets)
