@abstract class_name TelegraphValidator

static func MaximumSkillRange(telegraph: Telegraph) -> Variant:
	var parent = telegraph.ParentSkill.Parent
	var dist = parent.global_position.distance_to(telegraph.global_position) - parent.PhysicalSize
	if dist > telegraph.ParentSkill.Definition.TargetingMaxRange:
		return Error.new("Target is out of range.")
	return true

static func AtLeastOneTarget(telegraph: Telegraph) -> Variant:
	var targets = telegraph.FilteredOnlyTargets
	if targets.size() == 0:
		return Error.new("No target.")
	return true

static func MaximumSkillRangeTargetingActor(telegraph: Telegraph) -> Variant:
	var targets = telegraph.FilteredOnlyTargets
	if targets.size() == 0:
		return true

	var parent = telegraph.ParentSkill.Parent
	var dist = parent.global_position.distance_to(telegraph.global_position) - parent.PhysicalSize - targets[0].PhysicalSize
	if dist > telegraph.ParentSkill.Definition.TargetingMaxRange:
		return Error.new("Target is out of range.")
	return true
