@abstract class_name TelegraphProcessor

static func ConstantTint(color: Color):
	return func(telegraph: Telegraph):
		telegraph.Tint = color

static func SnapToHoveredActor(telegraph: Telegraph):
	for actor in Actor.Repository.Hovered.List:
		if not telegraph.TargetValidator or telegraph.TargetValidator.call(actor):
			telegraph.global_position = actor.global_position
			return

static func TargetFactionTint(telegraph: Telegraph):
	if telegraph.ParentSkill.preparingInfuse and telegraph.Targets.size() > 0:
		telegraph.Tint = TelegraphColor.TargetAcquiredInfused
	elif telegraph.Targets.size() > 0:
		telegraph.Tint = TelegraphColor.TargetAcquired

static func InvisibleTint(telegraph: Telegraph):
	telegraph.Tint = Color.TRANSPARENT

static func InvisibleSelfTint(telegraph: Telegraph):
	telegraph.SelfTint = Color.TRANSPARENT

static func OutOfRangeTint(telegraph: Telegraph):
	var parent = telegraph.ParentSkill.parent
	var parentPosition = parent.global_position
	parentPosition.y = 0
	var telegraphPosition = telegraph.global_position
	telegraphPosition.y = 0
	var dist = parentPosition.distance_to(telegraphPosition) - parent.physicalSize
	if dist > telegraph.ParentSkill.definition.TargetingMaxRange:
		telegraph.Tint = TelegraphColor.OutOfRange

static func NoTransparency(telegraph: Telegraph):
	telegraph.Tint = Color(telegraph.Tint.r, telegraph.Tint.g, telegraph.Tint.b, 1.0)

static func LookAtMouse(telegraph: Telegraph):
	var target = telegraph.ParentSkill.parent.InputProvider.CursorPosition
	target.y = telegraph.global_position.y
	telegraph.look_at(target)

static func ApplyCollisionRules(telegraph: BeamTelegraph):
	return ApplyCollisionRulesCustom(telegraph, 0.1)

static func ApplyCollisionRulesCustom(telegraph: BeamTelegraph, wallPenetration: float = 0.0, bufferDist: float = 0.0) -> Array[Actor]:
	var definition = telegraph.definition
	var mask = telegraph.definition.collisionMask
	var excludeMask = CollisionLayer.IGNORED_COVER

	var initialExclude: Array[RID] = [telegraph.ParentSkill.parent.get_rid()]
	if telegraph.definition.projectileCanHitCaster:
		initialExclude = []

	var contacts = telegraph.GatherBeamContacts(mask, initialExclude)

	telegraph.length = definition.RectLength
	var piercingLeft = definition.PiercingPower
	var penetrationLeft = definition.PenetrationPower

	var ignoredGroups: Dictionary[StringName, bool] = {}
	for group in telegraph.IgnoredObstacleGroups:
		ignoredGroups[group] = true

	var piercedGroups: Dictionary[StringName, bool] = {}

	var targetsHit: Array[Actor]

	for contact in contacts:
		var collider = contact.Collider
		if collider is not Actor:
			continue

		if collider.collision_layer & excludeMask > 0:
			continue

		if isInHitGroup(collider, ignoredGroups):
			continue

		if isInHitGroup(collider, piercedGroups):
			targetsHit.push_back(collider)
			continue

		var isActor = collider.collision_layer & CollisionLayer.ACTOR != 0

		if isActor and not (telegraph.TargetValidator.call(collider) as bool):
			continue

		var isLowCover = collider.collision_layer & CollisionLayer.LOW_COVER != 0
		var isHighCover = collider.collision_layer & CollisionLayer.HIGH_COVER != 0
		var isFullCover = collider.collision_layer & CollisionLayer.FULL_COVER != 0

		if isActor and piercingLeft > 0:
			piercingLeft -= 1
			rememberGroups(collider, piercedGroups)
			targetsHit.push_back(collider)
			continue

		if isLowCover and penetrationLeft > 0:
			penetrationLeft -= 1
			rememberGroups(collider, piercedGroups)
			targetsHit.push_back(collider)
			continue

		if isHighCover and penetrationLeft >= 2:
			penetrationLeft -= 2
			rememberGroups(collider, piercedGroups)
			targetsHit.push_back(collider)
			continue

		if isFullCover and penetrationLeft >= 4:
			penetrationLeft -= 4
			rememberGroups(collider, piercedGroups)
			targetsHit.push_back(collider)
			continue

		if isActor:
			telegraph.length = minf(contact.Distance - bufferDist, definition.RectLength)
		else:
			var hit = telegraph.DistanceToContact(contact, contacts, mask, initialExclude)
			telegraph.length = hit + wallPenetration

		targetsHit.push_back(collider)
		break

	return targetsHit

static func isInHitGroup(collider: Node, hitGroups: Dictionary[StringName, bool]) -> bool:
	for group in collider.get_groups():
		if group.begins_with("obstaclegroup_") and hitGroups.has(group):
			return true
	return false

static func rememberGroups(collider: Node, hitGroups: Dictionary[StringName, bool]):
	for group in collider.get_groups():
		if group.begins_with("obstaclegroup_"):
			hitGroups[group] = true
