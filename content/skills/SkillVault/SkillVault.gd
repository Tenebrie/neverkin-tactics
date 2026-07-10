extends Skill
class_name SkillVault

var targetSelectorTelegraph = TelegraphPreset.SingleActor.new().allowObstacles()
var landingAreaTelegraph: TelegraphDefinition = TelegraphPreset.PointArea.new(0.0)
var targetedActor: Actor

func _prepare() -> void:
	landingAreaTelegraph.created.connect(func(telegraph: CircularTelegraph):
		telegraph.radius = Parent.physicalSize
	)

	landingAreaTelegraph.Processors.push_back(func(telegraph: Telegraph):
		var targetTint = Color.TRANSPARENT
		if targetedActor:
			var partnerPosition = ActorUtils.flatPositionOf(targetedActor)
			var jumpVector = (partnerPosition - ActorUtils.flatPositionOf(Parent)).normalized()
			var landingSpot = partnerPosition + jumpVector * (Parent.physicalSize + 0.25 + targetedActor.physicalSize)
			telegraph.global_position = landingSpot

			if telegraph.IsPathable(Parent.physicalSize):
				targetTint = TelegraphColor.ExclusionGood
			else:
				targetTint = TelegraphColor.ExclusionOccupied

		telegraph.Tint = targetTint
	)

	landingAreaTelegraph.Validators = []
	landingAreaTelegraph.Validators.push_back(func(telegraph: Telegraph):
		if not telegraph.IsPathable(Parent.physicalSize):
			return Error.new("Not enough free space at destination.")
	)

	landingAreaTelegraph.Attachment = Telegraph.Attachment.None

	targetSelectorTelegraph.addTargetFilter(func(target):
		return target is Prop or not ActorUtils.isHostileTo(target, Parent) and target != Parent
	)
	targetSelectorTelegraph.targetsChanged.connect(func(targets):
		if targets.size() > 0:
			targetedActor = targets[0]
		else:
			targetedActor = null
	)
	Definition.Telegraphs = [
		TelegraphPreset.MaxCastRange.new(),
		targetSelectorTelegraph,
		landingAreaTelegraph
	]

func _cast(targets: TargetData) -> void:
	create_tween().tween_property(Parent, "global_position", targets.pointPerTelegraph[landingAreaTelegraph], 0.3)
	var collision = Parent.collision_layer
	Parent.collision_layer = 0
	await get_tree().create_timer(0.3).timeout
	Parent.collision_layer = collision
