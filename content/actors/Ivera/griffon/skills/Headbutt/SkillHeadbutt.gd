extends Skill
class_name SkillHeadbutt

const PrimaryDamage = 2
const SecondaryDamage = 2
const BonkDamage = 1

const PushDist = 5.0

const MaxWallSegmentsPushed = 5

const PushSpeed = 10.0

var dashTelegraph = TelegraphPreset.ForcePush.new(0.0)
var pushTelegraphs: Array[TelegraphPreset.ForcePush]

var _isPushedIntoObstacle = false
var _pushedVictims: Array[Actor]

func _prepare() -> void:
	dashTelegraph.Travel.RectLength = definition.TargetingMaxRange
	dashTelegraph.Travel.addTargetFilter(func(actor):
		return actor != parent
	)
	dashTelegraph.Travel.Attachment = Telegraph.Attachment.Caster
	dashTelegraph.Travel.addProcessor(func(tele):
		tele.position.y = -0.01
	)
	dashTelegraph.Travel.addProcessor(TelegraphProcessor.LookAtMouse)
	dashTelegraph.Travel.RectWidth = parent.physicalSize * 2

	dashTelegraph.Impact.addTargetFilter(func(actor):
		if actor is Prop and actor.get_parent() is PropWall wall:
			return wall.CanBeIgnored
		return actor != parent
	)
	dashTelegraph.Impact.HealthThreatSelector = func(actor):
		if _pushedVictims.has(actor) and _isPushedIntoObstacle:
			return PrimaryDamage + SecondaryDamage
		return PrimaryDamage

	dashTelegraph.Impact.addPostProcessor(func(impactInstance):
		var dashTargets = impactInstance.Targets
		if dashTargets.is_empty():
			for i in MaxWallSegmentsPushed:
				pushTelegraphs[i].Travel.getInstance().hide()
				pushTelegraphs[i].Impact.getInstance().hide()
			return


		var impactPoint = impactInstance.global_position
		impactPoint.y = 0.0

		var sortedTargets = dashTargets.slice(0)
		sortedTargets.sort_custom(func(a, b):
			var distOfA = ActorUtils.flatDistanceTo(a, impactPoint)
			var distOfB = ActorUtils.flatDistanceTo(b, impactPoint)
			return distOfA < distOfB
		)

		_pushedVictims = sortedTargets.slice(0, MaxWallSegmentsPushed)

		if sortedTargets.any(func(target): return target is not Prop):
			sortedTargets = sortedTargets.filter(func(t): return t is not Prop)
			_pushedVictims = [sortedTargets.front()]
		else:
			_isPushedIntoObstacle = false

		var momentumOriginPoint = (impactInstance.global_position + dashTelegraph.Travel.getInstance().global_position) / 2.0
		momentumOriginPoint.y = 0.0

		for i in _pushedVictims.size():
			pushTelegraphs[i].Travel.getInstance().show()
			pushTelegraphs[i].Impact.getInstance().show()
			var victim = _pushedVictims[i]
			var tele = pushTelegraphs[i].Travel.getInstance()
			tele.global_position = ActorUtils.flatPositionOf(victim)
			tele.position.y = -0.02
			tele.width = victim.physicalSize * 2.0

			var ignored: Array[StringName] = []
			for group in victim.get_groups():
				if String(group).begins_with("obstaclegroup_"):
					ignored.push_back(group)
			tele.IgnoredObstacleGroups = ignored

			var pushDirection = -ActorUtils.flatDirectionTo(tele, momentumOriginPoint)
			tele.look_at(tele.global_position + pushDirection * 10)

		for i in range(_pushedVictims.size(), MaxWallSegmentsPushed):
			pushTelegraphs[i].Travel.getInstance().hide()
			pushTelegraphs[i].Impact.getInstance().hide()
	)

	for i in MaxWallSegmentsPushed:
		var pushTelegraph = TelegraphPreset.ForcePush.new(PushDist)
		pushTelegraphs.push_back(pushTelegraph)
		if i == 0:
			pushTelegraph.Impact.addPostProcessor(func(tele):
				_isPushedIntoObstacle = not tele.Targets.is_empty()
			)
		pushTelegraph.Impact.HealthThreat = BonkDamage

	definition.telegraphs = [
		dashTelegraph.Travel,
		dashTelegraph.Impact,
	]
	for tele in pushTelegraphs:
		definition.telegraphs.push_back(tele.Travel)
		definition.telegraphs.push_back(tele.Impact)

func _cast(targets: TargetData) -> void:
	await SkillUtils.forceMoveTo(parent, targets.endpointPerTelegraph[dashTelegraph.Travel])

	if targets.perTelegraph[dashTelegraph.Impact].is_empty():
		return

	for target in targets.perTelegraph[dashTelegraph.Impact]:
		target.stats.dealDamage(DamageInstance.ForSkill(self, PrimaryDamage))

	var maxDuration = 0.0
	for i in _pushedVictims.size():
		var landing = targets.endpointPerTelegraph[pushTelegraphs[i].Travel]
		maxDuration = maxf(maxDuration, ActorUtils.flatDistanceTo(_pushedVictims[i], landing) / PushSpeed)
		_shoveVictim(_pushedVictims[i], pushTelegraphs[i], targets)

	if maxDuration > 0.0:
		await parent.get_tree().create_timer(maxDuration).timeout
		await parent.get_tree().process_frame
	NavmeshManager.Instance.rebakeNavmeshForCurrentActor()

func _shoveVictim(victim: Actor, pushTelegraph: TelegraphPreset.ForcePush, targets: TargetData) -> void:
	await SkillUtils.forceMoveTo(victim, targets.endpointPerTelegraph[pushTelegraph.Travel], PushSpeed)

	var rammed = targets.perTelegraph[pushTelegraph.Impact]
	for wall in rammed:
		wall.stats.dealDamage(DamageInstance.ForSkill(self, BonkDamage))

	if not rammed.is_empty():
		victim.stats.dealDamage(DamageInstance.ForSkill(self, SecondaryDamage))
		victim.buffs?.Add(BuffStunned.new())

	if victim is Prop:
		victim.Destroy()
