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
	if preparingInfuse:
		cooldownRemaining += 1

	var buff: Buff
	var effect = SkillSpeedControlEffect.new()
	get_tree().root.add_child(effect)
	effect.global_position = parent.global_position
	effect.global_position.y += 0.5
	var duration = 1.0
	effect.Play(targets.actor.global_position - parent.global_position, 10, duration)
	await get_tree().create_timer(duration).timeout
	if ActorUtils.isAlliedTo(targets.actor, parent):
		buff = BuffQuickened.new()
		if preparingInfuse:
			buff.Duration += 1
	else:
		buff = BuffSlowed.new()
		if preparingInfuse:
			buff.Duration += 1
	targets.actor.buffs.Add(buff)
