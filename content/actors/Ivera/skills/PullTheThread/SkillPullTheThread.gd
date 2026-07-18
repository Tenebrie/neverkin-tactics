extends Skill
class_name SkillPullTheThread

const BonkDamage = 2
const MaxPullDistance = 5.0

var mainTelegraph = TelegraphPreset.SingleActor.new()
var pushTelegraph = TelegraphPreset.ForcePush.new(MaxPullDistance)

func _prepare() -> void:
	mainTelegraph.addTargetFilter(func(actor):
		return actor != parent
	)

	mainTelegraph.addValidator(func(telegraph: Telegraph):
		if telegraph.FilteredOnlyTargets.size() == 0:
			return true
		if ActorUtils.isAlliedTo(telegraph.FilteredOnlyTargets[0], parent):
			return true
		if not telegraph.FilteredOnlyTargets[0].buffs.Has(BuffSoulbind):
			return Error.new("Target must be Soulbound")
		return true
	)

	mainTelegraph.HealthThreatSelector = func(actor):
		if pushTelegraph.Hits.is_empty():
			return 0
		return 0 if ActorUtils.isAlliedTo(actor, parent) else BonkDamage

	pushTelegraph.VictimSelector = func():
		var main = mainTelegraph.getInstance()
		if main.Targets.is_empty():
			return null
		return main.Targets[0]

	pushTelegraph.DirectionSelector = func(victim):
		return ActorUtils.flatPositionOf(parent) - ActorUtils.flatPositionOf(victim)

	pushTelegraph.Impact.IconPerTarget = preload("res://assets/icons/IconBonkVictim64.svg")
	pushTelegraph.Impact.HealthThreatSelector = func():
		if not pushTelegraph.Victim:
			return 0
		return 0 if ActorUtils.isAlliedTo(parent, pushTelegraph.Victim) else BonkDamage

	definition.telegraphs = [
		mainTelegraph,
		TelegraphPreset.MaxCastRange.new(),
		pushTelegraph.Travel,
		pushTelegraph.Impact,
	]

func _cast(targets: TargetData) -> void:
	var victim = targets.actor
	var landing = targets.endpointPerTelegraph[pushTelegraph.Travel]
	var dist = ActorUtils.flatDistanceTo(victim, landing)

	var victimDamageInstance = DamageInstance.ForSkillCast(victim, targets)
	var pushTelegraphReceiverDamage: Dictionary[Actor, DamageInstance]
	for actor in targets.perTelegraph[pushTelegraph.Impact]:
		pushTelegraphReceiverDamage[actor] = DamageInstance.ForSkillCast(actor, targets)

	var tween = create_tween()
	if ActorUtils.isAlliedTo(victim, parent) or targets.perTelegraph[pushTelegraph.Impact].is_empty():
		tween.tween_property(victim, "global_position", landing, 0.6).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_BACK)
	else:
		tween.tween_property(victim, "global_position", landing, dist / 8.0).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)

	await tween.finished
	NavmeshManager.Instance.rebakeNavmeshForCurrentActor()

	for actor in targets.perTelegraph[pushTelegraph.Impact]:
		actor.stats.dealDamage(pushTelegraphReceiverDamage[actor])

	if ActorUtils.isHostileTo(parent, victim) and not targets.perTelegraph[pushTelegraph.Impact].is_empty():
		victim.stats.dealDamage(victimDamageInstance)
		victim.buffs.Add(BuffStunned.new())
	victim.buffs.RemoveAll(BuffSoulbind)
