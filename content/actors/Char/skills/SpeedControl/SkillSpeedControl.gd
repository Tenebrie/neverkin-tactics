extends Skill
class_name SkillSpeedControl

const ExtraDuration = 1
const ExtraCooldown = 1

var targetTelegraph: TelegraphDefinition

func _prepare() -> void:
	targetTelegraph = TelegraphPreset.SingleActor.new().addTargetFilter(func(actor):
		return actor is not Prop
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
	if targets.infusedCast:
		cooldownRemaining += ExtraCooldown

	var buff: Buff
	var effect = SkillSpeedControlEffect.new()
	get_tree().root.add_child(effect)
	effect.global_position = parent.global_position
	effect.global_position.y += 0.5
	var effectDuration = 0.5
	effect.Play(targets.actor.global_position - parent.global_position, 10, effectDuration)
	await get_tree().create_timer(effectDuration).timeout
	if ActorUtils.isAlliedTo(targets.actor, parent):
		buff = BuffQuickened.new()
	else:
		buff = BuffSlowed.new()
	targets.actor.buffs.Add(buff)
	if targets.infusedCast:
		buff.Duration += ExtraDuration
