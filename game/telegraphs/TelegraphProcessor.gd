@abstract class_name TelegraphProcessor

static func ConstantTint(color: Color):
	return func(telegraph: Telegraph):
		telegraph.Tint = color

static func SnapToHoveredActor(telegraph: Telegraph):
	var hovered = telegraph.FilteredOnlyTargets
	if hovered.is_empty():
		return
	telegraph.global_position = hovered[0].global_position

static func TargetFactionTint(telegraph: Telegraph):
	if telegraph.Targets.size() > 0:
		telegraph.Tint = TelegraphColor.TargetAcquired

static func InvisibleTint(telegraph: Telegraph):
	telegraph.Tint = Color.TRANSPARENT

static func OutOfRangeTint(telegraph: Telegraph):
	var parent = telegraph.ParentSkill.Parent
	var parentPosition = parent.global_position
	parentPosition.y = 0
	var telegraphPosition = telegraph.global_position
	telegraphPosition.y = 0
	var dist = parentPosition.distance_to(telegraphPosition) - parent.PhysicalSize
	if dist > telegraph.ParentSkill.Definition.TargetingMaxRange:
		telegraph.Tint = TelegraphColor.OutOfRange

static func NoTransparency(telegraph: Telegraph):
	telegraph.Tint = Color(telegraph.Tint.r, telegraph.Tint.g, telegraph.Tint.b, 1.0)

static func LookAtMouse(telegraph: Telegraph):
	var target = telegraph.ParentSkill.Parent.InputProvider.CursorPosition
	target.y = telegraph.global_position.y
	telegraph.look_at(target)

static func ApplyCollisionRules(telegraph: RectangularTelegraph):
	var definition = telegraph.Definition
	var basis = telegraph.global_basis.orthonormalized()
	var direction = -basis.z
	var origin = Vector3(telegraph.global_position.x, telegraph.height / 2.0, telegraph.global_position.z)
	var mask = CollisionLayer.FULL_COVER | CollisionLayer.HIGH_COVER | CollisionLayer.LOW_COVER | CollisionLayer.ACTOR
	var excludeMask = CollisionLayer.IGNORED_COVER

	var initialExclude: Array[RID] = [telegraph.ParentSkill.Parent.get_rid()]

	var spaceState = telegraph.get_world_3d().direct_space_state
	var contacts = RaycastUtils.GatherBeamContacts(
		spaceState,
		Vector2(telegraph.width, telegraph.height),
		basis, origin, direction,
		definition.RectLength,
		mask, initialExclude,
	)

	telegraph.length = definition.RectLength
	var piercingLeft = definition.PiercingPower
	var penetrationLeft = definition.PenetrationPower

	var hitGroups: Dictionary[StringName, bool] = {}
	for group in telegraph.IgnoredObstacleGroups:
		hitGroups[group] = true

	var slab = BoxShape3D.new()

	for contact in contacts:
		var collider = contact.Collider
		if collider is not Actor:
			continue

		if collider.collision_layer & excludeMask > 0:
			continue

		if isInHitGroup(collider, hitGroups):
			continue

		var isActor = collider.collision_layer & CollisionLayer.ACTOR != 0

		if isActor and not (telegraph.TargetValidator.call(collider) as bool):
			continue

		var isLowCover = collider.collision_layer & CollisionLayer.LOW_COVER != 0
		var isHighCover = collider.collision_layer & CollisionLayer.HIGH_COVER != 0
		var isFullCover = collider.collision_layer & CollisionLayer.FULL_COVER != 0

		if isActor and piercingLeft > 0:
			piercingLeft -= 1
			rememberGroups(collider, hitGroups)
			continue

		if isLowCover and penetrationLeft > 0:
			penetrationLeft -= 1
			rememberGroups(collider, hitGroups)
			continue

		if isHighCover and penetrationLeft >= 2:
			penetrationLeft -= 2
			rememberGroups(collider, hitGroups)
			continue

		if isFullCover and penetrationLeft >= 4:
			penetrationLeft -= 4
			rememberGroups(collider, hitGroups)
			continue

		if isActor:
			telegraph.length = minf(contact.Distance, definition.RectLength)
		else:
			slab.size = Vector3(telegraph.width, telegraph.height, 0.05)
			var hit = RaycastUtils.ResolveContactDistance(
				spaceState, slab, basis, origin, direction,
				definition.RectLength, mask, contact.Rid, contacts, initialExclude,
			)
			telegraph.length = hit + 0.1
		return

static func isInHitGroup(collider: Node, hitGroups: Dictionary[StringName, bool]) -> bool:
	for group in collider.get_groups():
		if group.begins_with("obstaclegroup_") and hitGroups.has(group):
			return true
	return false

static func rememberGroups(collider: Node, hitGroups: Dictionary[StringName, bool]):
	for group in collider.get_groups():
		if group.begins_with("obstaclegroup_"):
			hitGroups[group] = true
