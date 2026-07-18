extends Skill
class_name SkillChainlink

const Damage = 2
const Healing = 2
const PropagationDistance = 5.0 # meters
const MaxTargets = 10

var cursorTelegraph = TelegraphPreset.CasterProjectile.new().WithWidth(0.04)
var chainLinks: Array[TelegraphPreset.WorldProjectile]

func _prepare() -> void:
	var chainTargets: Array[Actor]
	cursorTelegraph.PenetrationPower = 1000
	for i in MaxTargets:
		var link = TelegraphPreset.WorldProjectile.new().WithWidth(0.04)
		link.RectLength = 50.0
		link.collisionMask = CollisionLayer.ACTOR

		chainLinks.push_back(link)

	cursorTelegraph.HealthThreatSelector = func(actor):
		return 0 if ActorUtils.isAlliedTo(actor, parent) else Damage
	cursorTelegraph.HealthPromiseSelector = func(actor):
		return Healing if ActorUtils.isAlliedTo(actor, parent) else 0

	for link in chainLinks:
		link.addTargetFilter(func(actor, telegraph):
			var index = chainLinks.find(telegraph.definition)
			return chainTargets.size() > index and actor == chainTargets[index]
		)
		link.HealthThreatSelector = func(actor):
			return 0 if ActorUtils.isAlliedTo(actor, parent) else Damage
		link.HealthPromiseSelector = func(actor):
			return Healing if ActorUtils.isAlliedTo(actor, parent) else 0

	cursorTelegraph.addTargetFilter(func(actor):
		return actor is not Prop and actor.buffs.Has(BuffSoulbind)
	)

	cursorTelegraph.addProcessor(func(telegraph):
		chainTargets.clear()
		for link in chainLinks:
			link.getInstance().Tint = Color.TRANSPARENT

		if telegraph.Targets.size() == 0:
			return

		var currentTarget = telegraph.Targets[0]
		var excludedTargets: Array[Actor] = [currentTarget, parent]
		for link in chainLinks:
			var nextTarget = currentTarget.query
				.allLivingActors
				.exceptFor(excludedTargets)
				.inRange(PropagationDistance)
				.withBuff(BuffSoulbind)
				.nearest()
			if not nextTarget:
				break

			var linkInstance = link.getInstance() as BeamTelegraph
			linkInstance.definition.RectLength = PropagationDistance
			linkInstance.global_position = ActorUtils.flatPositionOf(currentTarget)
			linkInstance.look_at(ActorUtils.flatPositionOf(nextTarget))
			linkInstance.global_position.y = RenderHeight.TelegraphBase

			currentTarget = nextTarget
			chainTargets.push_back(currentTarget)
			excludedTargets.push_back(nextTarget)
	)

	cursorTelegraph.addPostProcessor(func(telegraph):
		if telegraph.Targets.size() == 0:
			return

		var targetPos = ActorUtils.flatPositionOf(telegraph.Targets[0])
		targetPos.y = telegraph.global_position.y
		telegraph.look_at(targetPos)
	)

	definition.telegraphs = [
		cursorTelegraph,
	]
	for link in chainLinks:
		definition.telegraphs.push_back(link)

func _cast(targets: TargetData) -> void:
	var effect = ProjectileSystem.Create(self)

	var theme = ProjectileSystem.ProjectileTheme.new()
	theme.trailColorGradient = preload("./effect/SkillChainlinkTrailGradient.tres")
	theme.trailTimeColorGradient = preload("./effect/SkillChainlinkTrailTimeGradient.tres")
	effect.theme = theme

	var projectileDef = ProjectileSystem.Definition.new()
	projectileDef.lingerTime = 1.0
	projectileDef.pointCount = 200

	var allLinks = chainLinks.slice(0)
	allLinks.push_front(cursorTelegraph)

	var currentTarget = parent
	for link in allLinks:
		var linkTargets = targets.perTelegraph[link]
		if linkTargets.is_empty():
			break

		var nextTarget = linkTargets[0]
		projectileDef.travelTime = ActorUtils.flatDistanceBetween(currentTarget, nextTarget) / 18.0

		effect.play(currentTarget, nextTarget, projectileDef)
		await get_tree().create_timer(projectileDef.travelTime).timeout
		nextTarget.stats.dealSkillDamage(targets)
		nextTarget.buffs.RemoveAll(BuffSoulbind)

		currentTarget = nextTarget
