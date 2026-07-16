@abstract class_name TelegraphPreset

class SelfCast extends TelegraphDefinition:
	func _init():
		Shape = Telegraph.Shape.Circle
		Attachment = Telegraph.Attachment.Caster
		TargetFilters.push_back(func(actor: Actor, telegraph: Telegraph):
			return actor == telegraph.ParentSkill.parent
		)
		Processors.push_back(TelegraphProcessor.ConstantTint(TelegraphColor.MaxRange))

	func Load(skill: Skill):
		CircleRadius = skill.parent.physicalSize + 0.05

class MaxCastRange extends TelegraphDefinition:
	func _init():
		Shape = Telegraph.Shape.Circle
		Attachment = Telegraph.Attachment.Caster
		TargetFilters.push_back(func(_a): return false)
		Processors.push_back(TelegraphProcessor.ConstantTint(TelegraphColor.MaxRange))

	func Load(skill: Skill):
		CircleRadius = skill.definition.TargetingMaxRange + skill.parent.physicalSize

class SingleActor extends TelegraphDefinition:
	func _init():
		Shape = Telegraph.Shape.Circle
		Attachment = Telegraph.Attachment.Mouse
		CircleRadius = 0.01
		Icon = preload("res://game/telegraphs/icons/common/target.png")

		Validators.push_back(TelegraphValidator.MaximumSkillRangeTargetingActor)
		Validators.push_back(TelegraphValidator.AtLeastOneTarget)

		Processors.push_back(TelegraphProcessor.SnapToHoveredActor)
		PostProcessors.push_back(TelegraphProcessor.OutOfRangeTint)
		PostProcessors.push_back(TelegraphProcessor.TargetFactionTint)
		PostProcessors.push_back(TelegraphProcessor.NoTransparency)

		addTargetFilter(func(actor: Actor) -> bool:
			return TurnManager.Instance.activeFaction != Actor.PlayerFaction or Actor.Repository.Hovered.List.has(actor)
		)

	func WithDamageToHostiles(damage: int):
		HealthThreat = damage
		TargetFilters.push_back(func(actor: Actor, _telegraph: Telegraph) -> bool:
			return ActorUtils.isTargetableBy(actor, ParentSkill.parent)
		)
		return self

class Projectile extends TelegraphDefinition:
	func _init():
		Shape = Telegraph.Shape.Rect
		Attachment = Telegraph.Attachment.Caster
		RectOrigin = BeamTelegraph.Origin.Start
		ShootFromCover = true

		Processors.push_back(TelegraphProcessor.LookAtMouse)
		Processors.push_back(TelegraphProcessor.ApplyCollisionRules)
		PostProcessors.push_back(TelegraphProcessor.TargetFactionTint)

	func Load(skill: Skill):
		RectLength = skill.definition.TargetingMaxRange

	func WithDamage(damage: int) -> Projectile:
		HealthThreat = damage
		return self

	func WithHealing(healing: int) -> Projectile:
		HealthPromise = healing
		return self

	func TargetingAllies() -> Projectile:
		TargetFilters.push_back(func(actor: Actor, _telegraph: Telegraph) -> bool:
			return ActorUtils.isAlliedTo(actor, ParentSkill.parent)
		)
		return self

	func TargetingHostiles() -> Projectile:
		TargetFilters.push_back(func(actor: Actor, _telegraph: Telegraph) -> bool:
			return ActorUtils.isTargetableBy(actor, ParentSkill.parent) && (actor.collision_layer & CollisionLayer.IGNORED_COVER) == 0
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
		TargetingHostiles()

class PointArea extends TelegraphDefinition:
	func _init(radius: float):
		Shape = Telegraph.Shape.Circle
		Attachment = Telegraph.Attachment.Mouse
		CircleRadius = radius

		Validators.push_back(TelegraphValidator.MaximumSkillRange)

		PostProcessors.push_back(TelegraphProcessor.TargetFactionTint)
		PostProcessors.push_back(TelegraphProcessor.OutOfRangeTint)

	func WithDamageToHostiles(damage: int) -> TelegraphDefinition:
		HealthThreat = damage
		TargetFilters.push_back(func(actor: Actor, _telegraph: Telegraph) -> bool:
			return ActorUtils.isTargetableBy(actor, ParentSkill.parent)
		)
		return self

class MouseText extends TelegraphDefinition:
	func _init(text: String):
		Shape = Telegraph.Shape.Circle
		Attachment = Telegraph.Attachment.Mouse
		CircleRadius = 0
		TextMessage = text
		Processors.push_back(func(telegraph: Telegraph):
			if not telegraph.childText:
				return
			telegraph.childText.offset = telegraph.get_viewport().get_mouse_position() - Vector2(telegraph.childText.size.x / 2, telegraph.childText.size.y + 8)
			telegraph.Tint = Color.WHITE
		)
