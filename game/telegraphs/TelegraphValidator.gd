@abstract class_name TelegraphValidator

static func MaximumSkillRange(telegraph: Telegraph) -> Variant:
	var parent = telegraph.ParentSkill.parent
	var dist = ActorUtils.flatDistanceBetween(parent, telegraph) - parent.physicalSize
	if dist > telegraph.ParentSkill.definition.TargetingMaxRange:
		return Error.new("Out of range")
	return true

static func AtLeastOneTarget(telegraph: Telegraph) -> Variant:
	var targets = telegraph.FilteredOnlyTargets
	if targets.size() == 0:
		return Error.new("No target")
	return true

static func MaximumSkillRangeTargetingActor(telegraph: Telegraph) -> Variant:
	var targets = telegraph.FilteredOnlyTargets
	if targets.size() == 0:
		return true

	var parent = telegraph.ParentSkill.parent
	var dist = ActorUtils.flatDistanceBetween(parent, targets[0]) - parent.physicalSize - targets[0].physicalSize
	if dist > telegraph.ParentSkill.definition.TargetingMaxRange:
		return Error.new("Out of range")
	return true
