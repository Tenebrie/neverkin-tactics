extends Skill
class_name SkillTrickshot

var Damage = 2
var Healing = 2
var HitboxWidth = 0.04

var damageTelegraph: TelegraphDefinition

var _pinnedOrigin: Vector3
var _hasPinnedOrigin: bool = false
var _lastEndpoint: Vector3
var _lastTravelLength: float = 0.0

func _prepare() -> void:
	damageTelegraph = TelegraphPreset.Projectile.new().WithWidth(HitboxWidth)

	damageTelegraph.HealthThreatSelector = func(actor: Actor) -> int:
		return Damage if ActorUtils.isTargetableBy(actor, parent) else 0
	damageTelegraph.HealthPromiseSelector = func(actor: Actor) -> int:
		return Healing if ActorUtils.isAlliedTo(actor, parent) else 0
	damageTelegraph.HealthThreat = Damage
	damageTelegraph.HealthPromise = Healing

	damageTelegraph.TargetFilters.push_back(func(actor: Actor, _t: Telegraph) -> bool:
		if ActorUtils.isAlliedTo(actor, parent) and actor.stats.healthDamageTaken > 0:
			return true
		return ActorUtils.isTargetableBy(actor, parent) and (actor.collision_layer & CollisionLayer.IGNORED_COVER) == 0
	)
	damageTelegraph.TargetFilters.push_back(func(actor: Actor, telegraph: Telegraph) -> bool:
		if not _hasPinnedOrigin:
			return true
		var d = ActorUtils.flatPositionOf(actor).distance_to(ActorUtils.flatPositionOf(telegraph))
		return d > actor.physicalSize + 0.05
	)
	definition.telegraphs = [
		damageTelegraph
	]
	damageTelegraph.Processors.push_front(func(telegraph: Telegraph):
		if _hasPinnedOrigin:
			telegraph.global_position = Vector3(_pinnedOrigin.x, telegraph.global_position.y, _pinnedOrigin.z)
	)
	damageTelegraph.Processors.push_back(func(telegraph: Telegraph):
		var rect = telegraph as RectangularTelegraph
		_lastTravelLength = rect.length
		_lastEndpoint = rect.global_position + (-rect.global_basis.z) * rect.length
	)
	Controller.SelectedSkillChanged.connect(func(current, previous):
		if current == self and previous != self:
			_hasPinnedOrigin = false
			damageTelegraph.projectileCanHitCaster = false
			damageTelegraph.ShootFromCoverOrigin = Vector3.ZERO
	)

	preparingInfuseChanged.connect(func():
		damageTelegraph.PiercingPower = 1 if preparingInfuse else 0
		definition.ManaCost = definition.base.ManaCost + (1 if preparingInfuse else 0)
	)

func getRecastCount() -> int:
	return 1

func isInfusable() -> bool:
	return parent.stats.manaCurrent >= 1

func _cast(targets: Skill.TargetData) -> void:
	var origin: Vector3 = _pinnedOrigin if _hasPinnedOrigin else parent.global_position
	var endpoint = _lastEndpoint
	var travelLength = _lastTravelLength

	var effect = SkillInfusedWeaponShotEffect.new()
	get_tree().root.add_child(effect)
	effect.global_position = origin
	effect.position.y += 0.5
	effect.infused = targets.infusedCast

	var localTarget = endpoint - origin
	localTarget.y = 0

	var duration = 0.2 * (travelLength / definition.TargetingMaxRange)
	effect.Play(localTarget, duration)

	for actor in targets.perTelegraph[damageTelegraph]:
		actor.stats.dealSkillDamage(targets)

	_pinnedOrigin = endpoint
	_hasPinnedOrigin = true
	if parent.actions.recastsRemaining > 0:
		MainCamera.Instance.snapToTarget(endpoint)
	damageTelegraph.ShootFromCoverOrigin = _pinnedOrigin
	damageTelegraph.projectileCanHitCaster = true

	if preparingInfuse:
		cooldownRemaining += 1
