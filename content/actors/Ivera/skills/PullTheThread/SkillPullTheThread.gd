extends Skill
class_name SkillPullTheThread

const BonkDamage = 2

var mainTelegraph: TelegraphDefinition = TelegraphPreset.SingleActor.new()
var travelTelegraph: TelegraphDefinition
var impactTelegraph: TelegraphDefinition

var _pullVictim: Actor
var _travelHits: Array[Actor] = []

func _prepare() -> void:
	mainTelegraph.addTargetFilter(func(actor):
		return actor != parent and actor is not Prop and actor.buffs
	)
	mainTelegraph.addPostProcessor(func(telegraph):
		if telegraph.Targets.is_empty():
			return
		_pullVictim = telegraph.Targets[0]
	)

	mainTelegraph.addValidator(func(telegraph: Telegraph):
		if telegraph.FilteredOnlyTargets.size() == 0:
			return true
		if not telegraph.FilteredOnlyTargets[0].buffs.Has(BuffSoulbind):
			return Error.new("Target must be Soulbound")
		return true
	)

	travelTelegraph = TelegraphDefinition.new()
	travelTelegraph.allowObstacles()
	travelTelegraph.projectileCanHitCaster = true
	travelTelegraph.Shape = Telegraph.Shape.Capsule
	travelTelegraph.RectOrigin = BeamTelegraph.Origin.Start
	travelTelegraph.RectWidth = 0.4 * 2
	travelTelegraph.RectLength = 5.0
	mainTelegraph.HealthThreatSelector = func(actor):
		if _travelHits.is_empty():
			return 0
		return 0 if ActorUtils.isAlliedTo(actor, parent) else BonkDamage

	travelTelegraph.addProcessor(func(telegraph):
		_travelHits = []
		var main = parent.telegraphs.FindTelegraph(mainTelegraph)
		if main.Targets.size() == 0:
			telegraph.Tint = Color.TRANSPARENT
			return

		telegraph.global_position = ActorUtils.flatPositionOf(main.Targets[0])
		telegraph.look_at(ActorUtils.flatPositionOf(parent))

		_travelHits = TelegraphProcessor.ApplyCollisionRulesCustom(telegraph, 0.0, 0.0)
		if _travelHits.is_empty():
			return

		telegraph.Tint = TelegraphColor.TargetAcquired
	)
	travelTelegraph.addTargetFilterOnTelegraph(func(actor, telegraph):
		return ActorUtils.flatDistanceBetween(actor, telegraph) >= 0.01
	)

	impactTelegraph = TelegraphDefinition.new()
	impactTelegraph.allowObstacles()
	impactTelegraph.Shape = Telegraph.Shape.Circle
	impactTelegraph.CircleRadius = 0.4
	impactTelegraph.HealthThreatSelector = func():
		if not _pullVictim:
			return 0
		return 0 if ActorUtils.isAlliedTo(parent, _pullVictim) else BonkDamage
	impactTelegraph.IconPerTarget = preload("res://assets/icons/IconBonkVictim64.svg")
	impactTelegraph.addTargetFilter(func(actor):
		return actor != _pullVictim
	)
	impactTelegraph.addProcessor(func(_t):
		if _pullVictim:
			impactTelegraph.CircleRadius = _pullVictim.physicalSize
	)
	impactTelegraph.addPostProcessor(func(telegraph: CircularTelegraph):
		if _travelHits.is_empty():
			telegraph.Tint = Color.TRANSPARENT
			telegraph.global_position = Vector3(100000, 100000, 100000)
			return

		var travel: BeamTelegraph = parent.telegraphs.FindTelegraph(travelTelegraph)
		var forward = -travel.global_basis.z

		telegraph.Tint = TelegraphColor.Invalid
		#telegraph.SelfTint = Color.TRANSPARENT
		telegraph.global_position = ActorUtils.flatPositionOf(_pullVictim) + forward * (travel.length + _pullVictim.physicalSize / 2.0)
		telegraph.global_position.y -= 0.01
	)

	definition.telegraphs = [
		mainTelegraph,
		TelegraphPreset.MaxCastRange.new(),
		travelTelegraph,
		impactTelegraph,
	]

func _cast(targets: TargetData) -> void:
	var victim = targets.actor
	var landing = targets.endpointPerTelegraph[travelTelegraph]
	var dist = ActorUtils.flatDistanceTo(victim, landing)

	var victimDamageInstance = DamageInstance.ForSkillCast(victim, targets)
	var bonkReceiverDamage: Dictionary[Actor, DamageInstance]
	for actor in targets.perTelegraph[impactTelegraph]:
		bonkReceiverDamage[actor] = DamageInstance.ForSkillCast(actor, targets)

	var tween = create_tween()
	if ActorUtils.isAlliedTo(victim, parent) or targets.perTelegraph[impactTelegraph].is_empty():
		tween.tween_property(victim, "global_position", landing, 0.4).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_BACK)
	else:
		tween.tween_property(victim, "global_position", landing, dist / 8.0).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)

	await tween.finished
	NavmeshManager.Instance.rebakeNavmeshForCurrentActor()

	for actor in targets.perTelegraph[impactTelegraph]:
		actor.stats.dealDamage(bonkReceiverDamage[actor])

	if not targets.perTelegraph[impactTelegraph].is_empty():
		victim.stats.dealDamage(victimDamageInstance)
		victim.buffs.Add(BuffStunned.new())
	victim.buffs.RemoveAll(BuffSoulbind)
