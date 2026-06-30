@abstract class_name TelegraphPreset

class SelfCast extends TelegraphDefinition:
	func _init():
		Shape = Telegraph.Shape.Circle
		Attachment = Telegraph.Attachment.Caster
		TargetFilter = func(_a): return false
		Processors.push_back(TelegraphProcessor.ConstantTint(TelegraphColor.MaxRange))

	func Load(skill: Skill):
		CircleRadius = skill.Parent.PhysicalSize + 0.05

class MaxCastRange extends TelegraphDefinition:
	func _init():
		Shape = Telegraph.Shape.Circle
		Attachment = Telegraph.Attachment.Caster
		TargetFilter = func(_a): return false
		Processors.push_back(TelegraphProcessor.ConstantTint(TelegraphColor.MaxRange))

	func Load(skill: Skill):
		CircleRadius = skill.Definition.TargetingMaxRange + skill.Parent.PhysicalSize

class SingleActor extends TelegraphDefinition:
	func _init():
		Shape = Telegraph.Shape.Circle
		Attachment = Telegraph.Attachment.Mouse
		CircleRadius = 0.10

		Validators.push_back(TelegraphValidator.MaximumSkillRange)
		Validators.push_back(TelegraphValidator.AtLeastOneTarget)

		Processors.push_back(TelegraphProcessor.SnapToHoveredActor)
		Processors.push_back(TelegraphProcessor.OutOfRangeTint)
		Processors.push_back(TelegraphProcessor.TargetAllianceTint)

	func Load(_skill: Skill):
		pass

	func WithDamageToHostiles(damage: int):
		HealthThreat = damage
		TargetFilter = func(actor: Actor) -> bool:
			return actor.Definition.Alliance == Actor.Alliance.Hostile and Actor.Repository.Hovered.List.has(actor)
		return self

class Projectile extends TelegraphDefinition:
	func _init():
		Shape = Telegraph.Shape.Rect
		Attachment = Telegraph.Attachment.Caster
		RectOrigin = RectangularTelegraph.Origin.Start

		Processors.push_back(TelegraphProcessor.LookAtMouse)
		Processors.push_back(TelegraphProcessor.TargetAllianceTint)

	func Load(skill: Skill):
		RectLength = skill.Definition.TargetingMaxRange

	func WithDamageToHostiles(damage: int):
		HealthThreat = damage
		TargetFilter = func(actor: Actor) -> bool:
			return actor.Definition.Alliance == Actor.Alliance.Hostile
		return self

	func WithWidth(width: float):
		RectWidth = width
		return self

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
		TargetFilter = func(actor: Actor) -> bool:
			return actor.Definition.Alliance == Actor.Alliance.Hostile
		return self
