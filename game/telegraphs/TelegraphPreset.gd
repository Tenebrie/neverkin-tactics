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
			print(actor, Actor.Repository.Hovered.List.has(actor))
			return actor.Definition.Alliance != Actor.Alliance.Player and Actor.Repository.Hovered.List.has(actor)
		)
		return self

class Projectile extends TelegraphDefinition:
	var PiercingPower = 0
	var PierceLowCover = 0

	func _init():
		Shape = Telegraph.Shape.Rect
		Attachment = Telegraph.Attachment.Caster
		RectOrigin = RectangularTelegraph.Origin.Start

		Processors.push_back(TelegraphProcessor.LookAtMouse)
		Processors.push_back(TelegraphProcessor.TargetAllianceTint)
		Processors.push_back(func(telegraph: RectangularTelegraph):
			var spaceState = telegraph.get_world_3d().direct_space_state
			var origin = Vector3(telegraph.global_position.x, 0, telegraph.global_position.z)
			var direction = -telegraph.global_basis.z
			var targetVector = direction * RectLength
			var mask = CollisionLayer.HIGH_COVER | CollisionLayer.LOW_COVER | CollisionLayer.ACTOR

			var actorsFound = 0
			var lowCoverFound = 0
			var highCoverFound = 0
			var rayOrigin = origin
			var exclude: Array[RID] = [telegraph.ParentSkill.Parent.get_rid()]
			var resolved = false

			while true:
				var query = PhysicsRayQueryParameters3D.create(rayOrigin, origin + targetVector)
				query.collision_mask = mask
				query.exclude = exclude
				var result = spaceState.intersect_ray(query)
				if not result:
					break

				var layer = result.collider.collision_layer

				if layer & CollisionLayer.ACTOR and result.collider is Actor:
					var isValidTarget = telegraph.TargetValidator.call(result.collider) as bool
					if not isValidTarget:
						exclude.append(result.rid)
						rayOrigin = result.position + direction * 0.01
						continue
					actorsFound += 1
					if PiercingPower >= actorsFound + highCoverFound:
						exclude.append(result.rid)
						rayOrigin = result.position + direction * 0.01
						continue
					var actorPos = result.collider.global_position
					telegraph.length = origin.distance_to(Vector3(actorPos.x, 0, actorPos.z))
					resolved = true
					break
				elif layer & CollisionLayer.HIGH_COVER:
					highCoverFound += 1
					if PiercingPower >= actorsFound + highCoverFound:
						exclude.append(result.rid)
						rayOrigin = result.position + direction * 0.01
						continue
					telegraph.length = origin.distance_to(result.position) + 0.1
					resolved = true
					break
				elif layer & CollisionLayer.LOW_COVER:
					lowCoverFound += 1
					exclude.append(result.rid)
					rayOrigin = result.position + direction * 0.01
				else:
					exclude.append(result.rid)
					rayOrigin = result.position + direction * 0.01

			if not resolved:
				telegraph.length = RectLength
		)

	func Load(skill: Skill):
		RectLength = skill.Definition.TargetingMaxRange

	func WithDamage(damage: int) -> Projectile:
		HealthThreat = damage
		return self

	func TargetingPlayer() -> Projectile:
		TargetFilters.push_back(func(actor: Actor) -> bool:
			return actor.Definition.Alliance != Actor.Alliance.Hostile
		)
		return self

	func AvoidingLowCover() -> Projectile:
		TargetFilters.push_back(func(actor: Actor) -> bool:
			return actor.collision_layer & CollisionLayer.LOW_COVER == 0
		)
		return self

	func TargetingHostiles() -> Projectile:
		TargetFilters.push_back(func(actor: Actor) -> bool:
			return actor.Definition.Alliance != Actor.Alliance.Player
		)
		return self

	func WithWidth(width: float) -> Projectile:
		RectWidth = width
		return self

	func Invisible() -> Projectile:
		Processors.push_back(TelegraphProcessor.InvisibleTint)
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
		TargetFilters.push_back(func(actor: Actor) -> bool:
			return actor.Definition.Alliance == Actor.Alliance.Hostile
		)
		return self
