extends Skill
class_name SkillWeaveTogether

const MaxTargets = 10
const MaxPushDistance = 5.0

var mainTelegraph = TelegraphPreset.PointArea.new(5.0).addPostProcessor(TelegraphProcessor.InvisibleSelfTint)
var pushTelegraphs: Array[TelegraphPreset.ForcePush]

var _sortedTargets: Array[Actor]

func _prepare() -> void:
	mainTelegraph.Icon = preload("res://game/telegraphs/icons/common/target.png")
	mainTelegraph.addProcessor(func(mainInstance):
		_sortedTargets = mainInstance.Targets.slice(0)
		_sortedTargets.sort_custom(func(a, b) -> bool:
			var distToA = ActorUtils.flatDistanceTo(a, mainInstance.global_position)
			var distToB = ActorUtils.flatDistanceTo(b, mainInstance.global_position)
			return distToA < distToB
		)
	)

	for i in MaxTargets:
		var telegraph = TelegraphPreset.ForcePush.new(MaxPushDistance)
		telegraph.VictimSelector = func():
			if _sortedTargets.size() <= i:
				return null
			return _sortedTargets[i]
		telegraph.DirectionSelector = func(victim):
			return ActorUtils.flatDirectionTo(victim, mainTelegraph.getInstance().global_position)
		telegraph.Travel.Processors.push_front(func(beamInstance: BeamTelegraph):
			if _sortedTargets.size() <= i:
				return
			var maxLength = ActorUtils.flatDistanceTo(_sortedTargets[i], mainTelegraph.getInstance().global_position)
			beamInstance.definition.RectLength = maxLength
		)

		pushTelegraphs.push_back(telegraph)

	definition.telegraphs = [
		mainTelegraph
	]
	for i in MaxTargets:
		definition.telegraphs.push_back(pushTelegraphs[i].Travel)
		definition.telegraphs.push_back(pushTelegraphs[i].Impact)
