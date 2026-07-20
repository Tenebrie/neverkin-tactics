extends Skill
class_name SkillGriffonToss

var LandingDamage = 3

var grabTelegraph = TelegraphPreset.SingleActor.new()
var landingPointTelegraph = TelegraphPreset.PointArea.new(0.1)
var currentTossTarget: Actor

const GrabRange = 1.0

func _prepare() -> void:
	var maxCastRange = TelegraphPreset.MaxCastRange.new()
	maxCastRange.addProcessor(func(telegraph: CircularTelegraph):
		definition.TargetingMaxRange = definition.base.TargetingMaxRange if currentTossTarget else GrabRange
		telegraph.radius = parent.physicalSize + definition.TargetingMaxRange
	)

	cleanUp.connect(func():
		currentTossTarget = null
	)

	grabTelegraph.addProcessor(func(telegraph):
		if currentTossTarget:
			telegraph.global_position = currentTossTarget.global_position
	)
	grabTelegraph.DisabledSelector = func():
		return currentTossTarget != null

	landingPointTelegraph.Validators.push_back(func(telegraph: Telegraph):
		if not currentTossTarget:
			return true
		if not telegraph.IsPathable(currentTossTarget.physicalSize):
			return Error.new("Not enough free space at destination.")
		return true
	)

	landingPointTelegraph.Processors = []
	landingPointTelegraph.Processors.push_back(func(telegraph: CircularTelegraph):
		if not currentTossTarget:
			telegraph.Tint = Color.TRANSPARENT
			return
		if telegraph.IsPathable(currentTossTarget.physicalSize):
			telegraph.Tint = TelegraphColor.ExclusionGood
		else:
			telegraph.Tint = TelegraphColor.ExclusionOccupied
		telegraph.radius = currentTossTarget.physicalSize
	)
	landingPointTelegraph.Processors.push_back(TelegraphProcessor.OutOfRangeTint)

	landingPointTelegraph.DisabledSelector = func():
		return currentTossTarget == null

	definition.telegraphs = [
		maxCastRange,
		grabTelegraph,
		landingPointTelegraph,
	]

func getPrecastCount() -> int:
	return 1

func _cast(targets: TargetData) -> void:
	if not currentTossTarget:
		currentTossTarget = targets.perTelegraph[grabTelegraph].front()
		return

	#currentTossTarget.buffs.RemoveAll(SkillGriffonGripBuff)
	await SkillUtils.forceMoveTo(currentTossTarget, targets.pointPerTelegraph[landingPointTelegraph], 15.0)
	currentTossTarget.stats.dealDamage(DamageInstance.ForSkill(self, LandingDamage))
	currentTossTarget.buffs.Add(BuffCrippled.new())
