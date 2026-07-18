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
		collisionMask = 0

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

class WorldProjectile extends TelegraphDefinition:
	func _init():
		Shape = Telegraph.Shape.Rect
		RectOrigin = BeamTelegraph.Origin.Start
		collisionMask = CollisionLayer.SKILL_TARGETABLE

		Processors.push_back(TelegraphProcessor.ApplyCollisionRules)
		PostProcessors.push_back(TelegraphProcessor.TargetFactionTint)

	func WithDamage(damage: int) -> WorldProjectile:
		HealthThreat = damage
		return self

	func WithHealing(healing: int) -> WorldProjectile:
		HealthPromise = healing
		return self

	func TargetingAllies() -> WorldProjectile:
		TargetFilters.push_back(func(actor: Actor, _telegraph: Telegraph) -> bool:
			return ActorUtils.isAlliedTo(actor, ParentSkill.parent)
		)
		return self

	func TargetingHostiles() -> WorldProjectile:
		TargetFilters.push_back(func(actor: Actor, _telegraph: Telegraph) -> bool:
			return ActorUtils.isTargetableBy(actor, ParentSkill.parent) && (actor.collision_layer & CollisionLayer.IGNORED_COVER) == 0
		)
		return self

	func WithWidth(width: float) -> WorldProjectile:
		RectWidth = width
		return self

	func Invisible() -> WorldProjectile:
		Processors.push_back(TelegraphProcessor.InvisibleTint)
		return self

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

class CasterProjectile extends WorldProjectile:
	func _init():
		super._init()
		ShootFromCover = true
		Attachment = Telegraph.Attachment.Caster
		collisionMask = CollisionLayer.SKILL_TARGETABLE

		Processors.push_front(TelegraphProcessor.LookAtMouse)

		addTargetFilter(func(actor):
			return projectileCanHitCaster or actor != ParentSkill.parent
		)

	func Load(skill: Skill):
		super.Load(skill)
		RectLength = skill.definition.TargetingMaxRange
