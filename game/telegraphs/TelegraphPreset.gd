@abstract class_name TelegraphPreset

class SelfCast extends TelegraphDefinition:
	func _init():
		Shape = Telegraph.Shape.Circle
		Attachment = Telegraph.Attachment.Caster
		TargetFilters.push_back(func(_a): return false)
		Processors.push_back(TelegraphProcessor.ConstantTint(TelegraphColor.MaxRange))

	func Load(skill: Skill):
		CircleRadius = skill.Parent.PhysicalSize + 0.05

class MaxCastRange extends TelegraphDefinition:
	func _init():
		Shape = Telegraph.Shape.Circle
		Attachment = Telegraph.Attachment.Caster
		TargetFilters.push_back(func(_a): return false)
		Processors.push_back(TelegraphProcessor.ConstantTint(TelegraphColor.MaxRange))

	func Load(skill: Skill):
		CircleRadius = skill.Definition.TargetingMaxRange + skill.Parent.PhysicalSize

class SingleActor extends TelegraphDefinition:
	func _init():
		Shape = Telegraph.Shape.Circle
		Attachment = Telegraph.Attachment.Mouse
		CircleRadius = 0.01
		Icon = preload("res://game/telegraphs/icons/common/target.png")

		Validators.push_back(TelegraphValidator.MaximumSkillRangeTargetingActor)
		Validators.push_back(TelegraphValidator.AtLeastOneTarget)

		Processors.push_back(TelegraphProcessor.SnapToHoveredActor)
		Processors.push_back(TelegraphProcessor.OutOfRangeTint)
		Processors.push_back(TelegraphProcessor.TargetAllianceTint)
		Processors.push_back(TelegraphProcessor.NoTransparency)

	func Load(_skill: Skill):
		pass

	func WithDamageToHostiles(damage: int):
		HealthThreat = damage
		TargetFilters.push_back(func(actor: Actor) -> bool:
			return actor.Definition.Alliance != Actor.Alliance.Player and Actor.Repository.Hovered.List.has(actor)
		)
		return self

class Projectile extends TelegraphDefinition:
	func _init():
		Shape = Telegraph.Shape.Rect
		Attachment = Telegraph.Attachment.Caster
		RectOrigin = RectangularTelegraph.Origin.Start
		ShootFromCover = true

		Processors.push_back(TelegraphProcessor.LookAtMouse)
		Processors.push_back(TelegraphProcessor.TargetAllianceTint)
		Processors.push_back(TelegraphProcessor.ApplyCollisionRules)

	func Load(skill: Skill):
		RectLength = skill.Definition.TargetingMaxRange

	func WithDamage(damage: int) -> Projectile:
		HealthThreat = damage
		return self

	func TargetingPlayer() -> Projectile:
		TargetFilters.push_back(func(actor: Actor) -> bool:
			return actor.Definition.Alliance != Actor.Alliance.Hostile && (actor.collision_layer & CollisionLayer.IGNORED_COVER) == 0
		)
		return self

	func TargetingHostiles() -> Projectile:
		TargetFilters.push_back(func(actor: Actor) -> bool:
			return actor.Definition.Alliance != Actor.Alliance.Player && (actor.collision_layer & CollisionLayer.IGNORED_COVER) == 0
		)
		return self

	func WithWidth(width: float) -> Projectile:
		RectWidth = width
		return self

	func Invisible() -> Projectile:
		Processors.push_back(TelegraphProcessor.InvisibleTint)
		return self

class StandardProjectile extends Projectile:
	func Load(skill: Skill):
		super.Load(skill)
		if skill.Parent.Definition.Alliance == Actor.Alliance.Player:
			TargetingHostiles()
		elif skill.Parent.Definition.Alliance == Actor.Alliance.Hostile:
			TargetingPlayer()

class PointArea extends TelegraphDefinition:
	func _init(radius: float):
		Shape = Telegraph.Shape.Circle
		Attachment = Telegraph.Attachment.Mouse
		CircleRadius = radius

		Validators.push_back(TelegraphValidator.MaximumSkillRange)

		Processors.push_back(TelegraphProcessor.TargetAllianceTint)
		Processors.push_back(TelegraphProcessor.OutOfRangeTint)

	func Load(_skill: Skill):
		pass

	func WithDamageToHostiles(damage: int) -> TelegraphDefinition:
		HealthThreat = damage
		TargetFilters.push_back(func(actor: Actor) -> bool:
			return actor.Definition.Alliance != Actor.Alliance.Player
		)
		return self
