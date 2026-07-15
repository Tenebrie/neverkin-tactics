extends Skill
class_name SkillManaDrain

const HealthDrain = 3
const ManaGained = 3
const PassiveRegen = 1

var targetTelegraph = TelegraphPreset.SingleActor.new()
var selfTelegraph = TelegraphPreset.SelfCast.new()

func _prepare() -> void:
	parent.turnStarted.connect(func():
		parent.stats.restoreMana(PassiveRegen)
	)

	selfTelegraph.Processors.push_back(TelegraphProcessor.InvisibleTint)
	selfTelegraph.addValidator(func(_t):
		var targetTelegraphInstance = parent.telegraphs.FindTelegraph(targetTelegraph)
		return not targetTelegraphInstance.Targets.is_empty()
	)
	targetTelegraph.addTargetFilter(func(actor: Actor):
		return actor is not Prop
	).addValidator(func(telegraph: Telegraph):
		var targets = telegraph.FilteredOnlyTargets
		if targets.is_empty():
			return true

		if targets[0].stats.healthDamageTaken == 0:
			return Error.new("Target is not damaged")
		return true
	)

	selfTelegraph.ManaPromise = ManaGained

	definition.telegraphs = [
		targetTelegraph,
		selfTelegraph,
		TelegraphPreset.MaxCastRange.new()
	]

func isCastable() -> Variant:
	if parent.stats.manaMissing == 0:
		return Error.new("No available mana capacity")
	return super.isCastable()

func _cast(targets: TargetData) -> void:
	var effect = SkillManaDrainEffect.new()
	get_tree().root.add_child(effect)
	effect.global_position = ActorUtils.flatPositionOf(targets.actor)
	effect.Play(ActorUtils.flatPositionOf(parent) - effect.global_position, ManaGained, 0.5)
	effect.global_position.y += 0.5

	var sequence = StartSequence()
	for i in HealthDrain:
		sequence.AddStep(0.1 * i, func():
			targets.actor.stats.reduceHealthMaximum(1)
		)

	for i in ManaGained:
		sequence.AddStep(0.5 + 0.1 * i, func():
			parent.stats.restoreMana(1)
		)

	await sequence.done
