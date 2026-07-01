@abstract class_name TelegraphProcessor

static func ConstantTint(color: Color):
	return func(telegraph: Telegraph):
		telegraph.Tint = color

static func SnapToHoveredActor(telegraph: Telegraph):
	var hovered = telegraph.FilteredOnlyTargets
	if hovered.is_empty():
		return
	telegraph.global_position = hovered[0].global_position

static func TargetAllianceTint(telegraph: Telegraph):
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
	var target = ActorUtils.GetMouseWorldPlanePosition(telegraph.get_viewport())
	target.y = telegraph.global_position.y
	telegraph.look_at(target)
