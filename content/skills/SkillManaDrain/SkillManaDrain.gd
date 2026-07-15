extends Skill
class_name SkillManaDrain

const HealthDrain = 1
const ManaGained = 2
const PassiveRegen = 1

var targetTelegraph = TelegraphPreset.SingleActor.new()
var selfTelegraph = TelegraphPreset.SelfCast.new()

func _prepare() -> void:
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
	targets.actor.stats.reduceHealthMaximum(HealthDrain)
	parent.stats.restoreMana(ManaGained)
