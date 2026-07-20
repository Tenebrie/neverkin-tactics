extends Skill
class_name SkillClawStrike

const Damage = 1
const MaxBleedStacks = 3
const MaxShiftedBleedStacks = 5

const DemolishRange = 0.35

var mainTelegraph = TelegraphPreset.SingleActor.new().WithDamageToHostiles(Damage).collideWithObstacles()
var demolishTelegraph = TelegraphPreset.PointArea.new(DemolishRange)

var currentMaxBleedStacks:
	get:
		if parent.isShapeshifted:
			return MaxShiftedBleedStacks
		return MaxBleedStacks

func _prepare() -> void:
	mainTelegraph.addPostProcessor(func(telegraph):
		if not telegraph.FirstTarget:
			demolishTelegraph.getInstance().SelfTint = Color.TRANSPARENT
	)

	demolishTelegraph.addTargetFilter(func(actor):
		if actor.get_parent() is PropWall wall:
			return wall.CanBeIgnored
		return actor is Prop
	)
	demolishTelegraph.collisionMask = CollisionLayer.SKILL_TARGETABLE | CollisionLayer.OBSTACLE
	demolishTelegraph.DisabledSelector = func():
		return not mainTelegraph.getInstance().FirstTarget or mainTelegraph.getInstance().FirstTarget is not Prop
	demolishTelegraph.Attachment = Telegraph.Attachment.None
	demolishTelegraph.Processors = []
	demolishTelegraph.PostProcessors = []
	demolishTelegraph.Validators = []
	demolishTelegraph.addProcessor(func(telegraph):
		telegraph.global_position = ActorUtils.flatPositionOf(mainTelegraph.getInstance().FirstTarget)
	)
	demolishTelegraph.HealthThreat = 100
	demolishTelegraph.addPostProcessor(func(telegraph):
		telegraph.SelfTint = Color.TRANSPARENT
		if not mainTelegraph.getInstance().FirstTarget:
			return

		telegraph.Tint = TelegraphColor.DangerArea
		for targetIcon in telegraph.TargetIcons.values():
			targetIcon.scale = Vector3(0.4, 0.4, 0.4)
	)
	demolishTelegraph.IconPerTarget = preload("res://assets/icons/IconDemolishVictim64.svg")

	definition.telegraphs = [
		mainTelegraph,
		demolishTelegraph,
		TelegraphPreset.MaxCastRange.new(),
	]

func _cast(targets: Skill.TargetData) -> void:
	var actor = targets.actor
	var effect = SkillClawStrikeEffect.new()
	get_tree().current_scene.add_child(effect)
	effect.global_position = actor.global_position
	effect.global_position.y = 2
	effect.Play()
	get_tree().create_timer(0.1).timeout.connect(func():
		actor.stats.dealSkillDamage(targets)
		actor.buffs?.AddUpToMaxIntensity(BuffBleeding.Build(self), MaxBleedStacks)

		if actor is Prop:
			actor.stats.dealDamage(DamageInstance.ForSkill(self, actor.stats.healthCurrent))

			for toDemolish in targets.perTelegraph[demolishTelegraph]:
				toDemolish.stats.dealSkillDamage(targets)
	)
