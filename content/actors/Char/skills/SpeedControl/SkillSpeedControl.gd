extends Skill
class_name SkillSpeedControl

const ExtraDuration = 1
const ExtraCooldown = 1

var targetTelegraph: TelegraphDefinition

func _prepare() -> void:
	targetTelegraph = TelegraphPreset.SingleActor.new().addTargetFilter(func(actor):
		return actor != parent and actor is not Prop
	)
	definition.telegraphs = [
		TelegraphPreset.MaxCastRange.new(),
		targetTelegraph
	]

	preparingInfuseChanged.connect(func():
		definition.ManaCost = definition.base.ManaCost + (1 if preparingInfuse else 0)
	)

func isInfusable() -> bool:
	return parent.stats.manaCurrent >= 1

func _cast(targets: TargetData) -> void:
	var buff: Buff
	if ActorUtils.isAlliedTo(targets.actor, parent):
		buff = BuffQuickened.new()
		if preparingInfuse:
			buff.Duration += 1
	else:
		buff = BuffSlowed.new()
		if preparingInfuse:
			buff.Duration += 1
	targets.actor.buffs.Add(buff)

	if preparingInfuse:
		cooldownRemaining += 1
