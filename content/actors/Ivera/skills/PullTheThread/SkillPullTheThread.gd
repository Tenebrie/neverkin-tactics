extends Skill
class_name SkillPullTheThread

const BonkDamage = 2

var mainTelegraph: TelegraphDefinition = TelegraphPreset.SingleActor.new()

func _prepare() -> void:
	mainTelegraph.addTargetFilter(func(actor):
		return actor != parent and actor is not Prop and actor.buffs
	)

	#mainTelegraph.addValidator(func(telegraph: Telegraph):
		#if telegraph.FilteredOnlyTargets.size() == 0:
			#return true
		#if not telegraph.FilteredOnlyTargets[0].buffs.Has(BuffSoulbind):
			#return Error.new("Target must be Soulbound")
		#return true
	#)

	var bonkTelegraph = TelegraphDefinition.new()
	bonkTelegraph.projectileCanHitCaster = true
	bonkTelegraph.Shape = Telegraph.Shape.Rect
	bonkTelegraph.RectOrigin = RectangularTelegraph.Origin.Start
	bonkTelegraph.RectWidth = 0.4 * 2
	bonkTelegraph.RectLength = definition.TargetingMaxRange + 0.4 * 2
	bonkTelegraph.addProcessor(func(telegraph):
		var main = parent.telegraphs.FindTelegraph(mainTelegraph)
		if main.Targets.size() == 0:
			telegraph.Tint = Color.TRANSPARENT
			return

		telegraph.global_position = ActorUtils.flatPositionOf(main.Targets[0])
		telegraph.look_at(ActorUtils.flatPositionOf(parent))

		var targetsHit = TelegraphProcessor.ApplyCollisionRulesCustom(telegraph, 0.0, 0.4)
		print(targetsHit)
	)
	bonkTelegraph.addTargetFilterOnTelegraph(func(actor, telegraph):
		return ActorUtils.flatDistanceBetween(actor, telegraph) >= 0.01
	)

	var bonkLandingTelegraph = TelegraphDefinition.new()
	bonkLandingTelegraph.Shape = Telegraph.Shape.Circle
	bonkLandingTelegraph.CircleRadius = 0.4
	bonkLandingTelegraph.addProcessor(func(telegraph: CircularTelegraph):
		var main = parent.telegraphs.FindTelegraph(mainTelegraph)
		if main.Targets.size() == 0:
			telegraph.Tint = Color.TRANSPARENT
			return

		var bonkInstance: RectangularTelegraph = parent.telegraphs.FindTelegraph(bonkTelegraph)
		telegraph.global_position = bonkInstance.global_position - bonkInstance.global_basis.z * (maxf(0.0, bonkInstance.length - telegraph.radius))
	)

	definition.telegraphs = [
		mainTelegraph,
		TelegraphPreset.MaxCastRange.new(),
		bonkTelegraph,
		bonkLandingTelegraph
	]
