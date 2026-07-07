extends Node
class_name BehaviourUtils

const BEAM_HEIGHT: float = 5.0
const BEAM_WIDTH: float = 0.1

#region Cover Check
class CoverMapCache:
	var actorIgnoredWalls: Dictionary[Actor, Array[RID]]
	var actorAttackSkills: Dictionary[Actor, Array[Skill]]

	func GetActorIgnoredWalls(actor: Actor):
		if actorIgnoredWalls.has(actor):
			return actorIgnoredWalls[actor]
		var value = PropWall.GetIgnoredWallRidsAt(actor.global_position, actor.Definition.PhysicalSize)
		actorIgnoredWalls[actor] = value
		return value

	func GetActorAttackSkills(actor: Actor):
		if actorAttackSkills.has(actor):
			return actorAttackSkills[actor]
		var value = BehaviourUtils.gatherAttackSkills(actor)
		actorAttackSkills[actor] = value
		return value

static func CreateActorCoverMap(actor: Actor) -> FloatFieldMap:
	var currentMapRid = actor.navigator.agent.get_navigation_map()
	var currentRegionRid = NavigationServer3D.map_get_closest_point_owner(currentMapRid, actor.global_position)

	var navMesh = NavmeshManager.Instance.GetRegion(currentRegionRid)
	if not navMesh:
		MessageLog.PrintMessage("Unable to find navmesh for CoverVisualizationLayer")
		return FloatFieldMap.Empty()

	## Collect interesting points to evaluate
	var gridSize = 0.25
	var start = Time.get_ticks_usec()
	var navmeshSample = NavmeshSampler.CollectNavmeshPoints(actor, gridSize, 1.0, 0.0)
	var elapsed = Time.get_ticks_usec() - start
	print("- Collecting points: %.2f ms" % [elapsed / 1000.0])

	start = Time.get_ticks_usec()
	## NPCs evaluate against their focus target. Otherwise, check all enemies.
	var threats = findEnemies(actor)
	var targets = threats
	if actor.Behaviour is ActorBehaviourWorldControlled npcBehaviour:
		targets = [npcBehaviour.FocusedTarget]
	elapsed = Time.get_ticks_usec() - start
	print("- Collecting enemies: %.2f ms" % [elapsed / 1000.0])

	var values: Dictionary[Vector2i, float]
	var cache = CoverMapCache.new()

	## Populate initial values
	start = Time.get_ticks_usec()
	for point in navmeshSample.points:
		var coverScore = EvaluateCoverScoreAtLocation(actor, point, targets, threats, cache)
		var cell = toCellCoordinates(point, gridSize)
		values[cell] = coverScore
	elapsed = Time.get_ticks_usec() - start
	print("- Collecting initial values: %.2f ms" % [elapsed / 1000.0])

	## Find each point's neighbours
	start = Time.get_ticks_usec()
	var neighbourDist = pow(actor.Definition.PhysicalSize * 2 - 0.05, 2)
	var neighboursOfCell: Dictionary[Vector2i, Array[Vector3]]
	for point in navmeshSample.points:
		var cell = toCellCoordinates(point, gridSize)
		if not values.has(cell):
			continue
		var validNeighbours: Array[Vector3]
		for other in navmeshSample.points:
			if other.distance_squared_to(point) < neighbourDist and point != other:
				validNeighbours.push_back(other)
		neighboursOfCell[cell] = validNeighbours
	elapsed = Time.get_ticks_usec() - start
	print("- Collecting neighbours: %.2f ms" % [elapsed / 1000.0])

	## Gaussian blur (kind of) the point values
	start = Time.get_ticks_usec()
	for i in range(3):
		var nextValues: Dictionary[Vector2i, float]
		for point in navmeshSample.points:
			var cell = toCellCoordinates(point, gridSize)
			if not values.has(cell):
				continue
			nextValues[cell] = values[cell] * 0.5
			var validNeighbours = neighboursOfCell[cell]
			for neighbour in validNeighbours:
				var neighbourValue = values[toCellCoordinates(neighbour, gridSize)]
				nextValues[cell] += neighbourValue / validNeighbours.size() / 2.0

		values = nextValues
		nextValues = {}
	elapsed = Time.get_ticks_usec() - start
	print("- Applying blur: %.2f ms" % [elapsed / 1000.0])

	## Produce a sorted array to easily access the best positions
	start = Time.get_ticks_usec()
	var scored: Array[FloatFieldMap.ScoredPoint] = []
	for point in navmeshSample.points:
		scored.push_back(FloatFieldMap.ScoredPoint.new(point, values[toCellCoordinates(point, gridSize)]))
	scored.sort_custom(func(a, b):
		return a.Score > b.Score
	)
	elapsed = Time.get_ticks_usec() - start
	print("- Sorting points: %.2f ms" % [elapsed / 1000.0])

	return FloatFieldMap.Build(values, navmeshSample.points, gridSize, scored)

static func toCellCoordinates(point: Vector3, gridSize: float) -> Vector2i:
	return Vector2i(int(floor(point.x / gridSize)), int(floor(point.z / gridSize)))

static func EvaluateCoverScoreAtLocation(
			actor: Actor,
			candidate: Vector3,
			targets: Array[Actor],
			threats: Array[Actor],
			cache: CoverMapCache
		) -> float:
	if targets.is_empty() and threats.is_empty():
		return 0.0
	var world = actor.get_world_3d()
	if world == null:
		return 0.0
	var space = world.direct_space_state

	var actorSkills = cache.GetActorAttackSkills(actor)

	var score = 0.0

	var weightHasShot = 1.0
	var weightAvoidLineOfSight = 1.0
	if actor.Behaviour is ActorBehaviourWorldControlled behaviour:
		weightHasShot = behaviour.WeightHasShot
		weightAvoidLineOfSight = behaviour.WeightAvoidLineOfSight

	## Agent shooting at the focused targets
	var ignoredWallsAtCandidate = PropWall.GetIgnoredWallRidsAt(candidate, actor.Definition.PhysicalSize)
	for enemy in targets:
		var actorShot = ShotContext.new()
		actorShot.space = space
		actorShot.from = candidate
		actorShot.to = enemy.global_position
		actorShot.shooter = actor
		actorShot.target = enemy
		actorShot.shooterSize = actor.PhysicalSize
		actorShot.IgnoredWalls = ignoredWallsAtCandidate
		for skill in actorSkills:
			score += scoreSkillUsable(actorShot, skill) * weightHasShot

	## Enemies shooting at the agent
	for enemy in threats:
		var enemyShot = ShotContext.new()
		enemyShot.space = space
		enemyShot.from = enemy.global_position
		enemyShot.to = candidate
		enemyShot.shooter = enemy
		enemyShot.target = actor
		enemyShot.shooterSize = enemy.PhysicalSize
		enemyShot.IgnoredWalls = cache.GetActorIgnoredWalls(enemy)
		if canBeShotBy(enemyShot):
			score -= weightAvoidLineOfSight * enemy.Stats.ThreatCurrent

	return score

class ShotContext:
	var space: PhysicsDirectSpaceState3D
	var from: Vector3
	var to: Vector3
	var shooter: Actor
	var target: Actor
	var shooterSize: float
	var IgnoredWalls: Array[RID]

	var flatDistance: float:
		get:
			return Vector2(to.x - from.x, to.z - from.z).length()

	static func FromLiveState(shootingActor: Actor, targetActor: Actor) -> ShotContext:
		var context = ShotContext.new()
		context.space = shootingActor.get_world_3d().direct_space_state
		context.from = ActorUtils.FlatPositionOf(shootingActor)
		context.to = ActorUtils.FlatPositionOf(targetActor)
		context.shooter = shootingActor
		context.target = targetActor
		context.shooterSize = shootingActor.Definition.PhysicalSize
		context.IgnoredWalls = PropWall.GetIgnoredWallRidsAt(context.from, context.shooterSize)
		return context

static func scoreSkillUsable(shot: ShotContext, skill: Skill) -> float:
	if shot.flatDistance > skill.Definition.TargetingMaxRange + shot.shooter.PhysicalSize:
		return 0.0
	if skill.Definition.BehaviourRequireLineOfSight:
		if not hasLineOfSight(shot):
			return 0.0
	return skill.Definition.BehaviourUsagePreference

static func hasLineOfSight(shot: ShotContext) -> bool:
	var flatFrom = Vector3(shot.from.x, 0.0, shot.from.z)
	var flatTo = Vector3(shot.to.x, 0.0, shot.to.z)
	var direction = flatTo - flatFrom
	var distance = direction.length()
	if distance < 0.01:
		return true
	direction = direction.normalized()

	var basis = Basis.looking_at(direction, Vector3.UP)
	var beamOrigin = Vector3(flatFrom.x, BEAM_HEIGHT / 2.0, flatFrom.z)
	var mask = CollisionLayer.FULL_COVER | CollisionLayer.HIGH_COVER | CollisionLayer.LOW_COVER

	var exclude: Array[RID] = [shot.shooter.get_rid(), shot.target.get_rid()]
	exclude.append_array(shot.IgnoredWalls)

	var contacts = RaycastUtils.GatherBeamContacts(
		shot.space, Vector2(BEAM_WIDTH, BEAM_HEIGHT), basis, beamOrigin, direction,
		distance, mask, exclude,
	)

	for contact in contacts:
		var collider = contact.Collider
		if collider.collision_layer & CollisionLayer.IGNORED_COVER != 0:
			continue
		return false
	return true

static func canBeShotBy(shot: ShotContext) -> bool:
	var flatFrom = Vector3(shot.from.x, 0.2, shot.from.z)
	var flatTo = Vector3(shot.to.x, 0.2, shot.to.z)
	var distance = (flatTo - flatFrom).length_squared()
	if distance < 0.0001:
		return true
	var mask = CollisionLayer.FULL_COVER | CollisionLayer.HIGH_COVER | CollisionLayer.LOW_COVER

	var exclude: Array[RID] = [shot.shooter.get_rid(), shot.target.get_rid()]
	exclude.append_array(shot.IgnoredWalls)

	var query = PhysicsRayQueryParameters3D.new()
	query.from = flatFrom
	query.to = flatTo
	query.collision_mask = mask
	query.exclude = exclude
	var result = shot.space.intersect_ray(query)
	return result.is_empty()

#endregion

#region Helpers
static func findEnemies(actor: Actor) -> Array[Actor]:
	var result: Array[Actor] = []
	for other in Actor.Repository.All.List:
		if other == actor:
			continue
		if not ActorUtils.IsHostileTo(other, actor):
			continue
		if not other.IsAlive:
			continue
		result.push_back(other)
	return result

static func gatherAttackSkills(actor: Actor) -> Array[Skill]:
	var out: Array[Skill] = []
	for i in 16:
		var skill = actor.Skills.GetByIndex(i)
		if skill == null:
			continue
		var hasDamage: bool = skill.Definition.Telegraphs.any(func(t): return t.HealthThreat > 0)
		if hasDamage:
			out.push_back(skill)
	return out
#endregion
