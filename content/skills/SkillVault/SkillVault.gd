extends Skill
class_name SkillVault

var targetSelectorTelegraph = TelegraphPreset.SingleActor.new().collideWithObstacles()
var landingAreaTelegraph: TelegraphDefinition = TelegraphPreset.PointArea.new(0.0)
var targetedActor: Actor

func _prepare() -> void:
	landingAreaTelegraph.created.connect(func(telegraph: CircularTelegraph):
		telegraph.radius = parent.physicalSize
	)

	landingAreaTelegraph.Processors.push_back(func(telegraph: Telegraph):
		var targetTint = Color.TRANSPARENT
		if targetedActor:
			var partnerPosition = ActorUtils.flatPositionOf(targetedActor)
			var jumpVector = (partnerPosition - ActorUtils.flatPositionOf(parent)).normalized()
			var landingSpot = partnerPosition + jumpVector * (parent.physicalSize + 0.25 + targetedActor.physicalSize)
			telegraph.global_position = landingSpot

			if telegraph.IsPathable(parent.physicalSize):
				targetTint = TelegraphColor.ExclusionGood
			else:
				targetTint = TelegraphColor.ExclusionOccupied

		telegraph.Tint = targetTint
	)

	landingAreaTelegraph.Validators = []
	landingAreaTelegraph.Validators.push_back(func(telegraph: Telegraph):
		if not telegraph.IsPathable(parent.physicalSize):
			return Error.new("Not enough free space at destination.")
		return true
	)

	landingAreaTelegraph.Attachment = Telegraph.Attachment.None

	targetSelectorTelegraph.addTargetFilter(func(target):
		return target is Prop or not ActorUtils.isHostileTo(target, parent) and target != parent
	)
	targetSelectorTelegraph.targetsChanged.connect(func(targets):
		if targets.size() > 0:
			targetedActor = targets[0]
		else:
			targetedActor = null
	)
	definition.telegraphs = [
		TelegraphPreset.MaxCastRange.new(),
		targetSelectorTelegraph,
		landingAreaTelegraph
	]

func _cast(targets: TargetData) -> void:
	create_tween().tween_property(parent, "global_position", targets.pointPerTelegraph[landingAreaTelegraph], 0.3)
	var collision = parent.collision_layer
	parent.collision_layer = 0
	await get_tree().create_timer(0.3).timeout
	parent.collision_layer = collision
