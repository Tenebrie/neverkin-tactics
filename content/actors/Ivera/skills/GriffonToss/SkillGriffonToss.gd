extends Skill
class_name SkillGriffonToss

var landingDamage = 3

var casterTelegraph = TelegraphPreset.PointArea.new(0.1)
var currentTossTarget: Actor

func _prepare() -> void:
	parent.Skills.BeforeSelectedSkillChanged.connect(func(current):
		if current != self:
			return

		var validTargets = Actor.Repository.Alive.List.filter(func(actor):
			return actor.buffs and actor.buffs.Has(SkillGriffonGripBuff) and ActorUtils.flatDistanceBetweenActors(actor, parent) <= 1.0
		)
		if validTargets.is_empty():
			return

		currentTossTarget = validTargets[0]
		casterTelegraph.CircleRadius = currentTossTarget.physicalSize
	)
	casterTelegraph.Validators.push_back(func(telegraph: Telegraph):
		if not telegraph.IsPathable(parent.physicalSize):
			return Error.new("Not enough free space at destination.")
	)

	casterTelegraph.Processors = []
	casterTelegraph.Processors.push_back(func(telegraph: Telegraph):
		if telegraph.IsPathable(parent.physicalSize):
			telegraph.Tint = TelegraphColor.ExclusionGood
		else:
			telegraph.Tint = TelegraphColor.ExclusionOccupied
	)
	casterTelegraph.Processors.push_back(TelegraphProcessor.OutOfRangeTint)

	definition.telegraphs = [
		casterTelegraph,
		TelegraphPreset.MaxCastRange.new()
	]

func isCastable() -> Variant:
	var validTargets = Actor.Repository.Alive.List.filter(func(actor):
		return actor.buffs and actor.buffs.Has(SkillGriffonGripBuff) and ActorUtils.flatDistanceBetweenActors(actor, parent) <= 1.0
	)
	if validTargets.is_empty():
		return Error.new("No grabbed target")
	return super.isCastable()

func _cast(targets: TargetData) -> void:
	if not currentTossTarget:
		return

	var collision = currentTossTarget.collision_layer
	currentTossTarget.collision_layer = 0
	await create_tween().tween_property(currentTossTarget, "global_position", targets.mousePoint, 0.4).finished
	currentTossTarget.collision_layer = collision
	currentTossTarget.stats.dealDamage(DamageInstance.ForSkill(self, landingDamage))
	currentTossTarget.buffs.RemoveAll(SkillGriffonGripBuff)
