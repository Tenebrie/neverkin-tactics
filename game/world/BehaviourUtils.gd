extends Node
class_name BehaviourUtils

const BEAM_WIDTH: float = 0.1

const gridSize = 0.5

static var WEIGHT_BLUR_ITERATIONS = 3

#region Cover Check
class MapTask:
	var navmeshSample: NavmeshSampler.Sample
	var physicsField: PhysicsField
	var actorOffensiveSkills: Array[SkillDefinition]
	var gridSize: float
	var navigationMapRid: RID

	var weightCover = 1.0
	var weightHasShot = 1.0
	var weightAvoidMeleeRange = 0.0
	var weightAvoidLineOfSight = 1.0
	var weightDistanceToMove = 1.0
	var weightProximityToAllies = 0.0
	var weightProximityToAlliesFalloffMeters = 10.0
	var weightProximityToEnemies = 1.0
	var weightProximityToEnemiesFalloffMeters = 10.0
	var weightOutOfFight = 1.0
	var weightOutOfFightMinDistance = 10.0

	var actor: ActorData
	var allies: Array[ActorData]
	var targets: Array[ActorData]
	var threats: Array[ActorData]
	var allWalls: Array[WallData]
	var ignorableWalls: Array[WallData]

	static func collect(actor: Actor, field: PhysicsField = null, sample: NavmeshSampler.Sample = null) -> MapTask:
		if not field:
			field = PhysicsField.new()
			field.obstacles = PropWall.collectPhysicsFieldObstacles()
		if not sample:
			sample = await NavmeshSampler.CollectNavmeshPoints(actor, BehaviourUtils.gridSize, 1.0)

		var task = MapTask.new()
		task.physicsField = field
		task.navmeshSample = sample
		task.gridSize = BehaviourUtils.gridSize
		task.navigationMapRid = actor.navigator.agent.get_navigation_map()
		task.actor = MapTask.ActorData.collect(actor)
		task.allWalls = PropWall.collectBehaviourMapTaskData(true)
		task.ignorableWalls = PropWall.collectBehaviourMapTaskData()
		task.actorOffensiveSkills = BehaviourUtils.gatherAttackSkills(actor)
		if actor.Behaviour is ActorBehaviourWorldControlled behaviour:
			task.weightCover = behaviour.WeightCover
			task.weightHasShot = behaviour.WeightHasShot
			task.weightAvoidMeleeRange = behaviour.WeightAvoidMeleeRange
			task.weightAvoidLineOfSight = behaviour.WeightAvoidLineOfSight
			task.weightDistanceToMove = behaviour.WeightDistanceToMove
			task.weightProximityToAllies = behaviour.WeightProximityToAllies
			task.weightProximityToAlliesFalloffMeters = behaviour.WeightProximityToAlliesFalloffMeters
			task.weightProximityToEnemies = behaviour.WeightProximityToEnemies
			task.weightProximityToEnemiesFalloffMeters = behaviour.WeightProximityToEnemiesFalloffMeters
			task.weightOutOfFight = behaviour.WeightOutOfFight
			task.weightOutOfFightMinDistance = behaviour.WeightOutOfFightMinDistance

		## Friendlies to chill close to
		var allies = BehaviourUtils.findAllies(actor)
		for ally in allies:
			task.allies.push_back(ActorData.collect(ally))

		## Enemies attacking this actor
		var threats = BehaviourUtils.findEnemies(actor)
		for threat in threats:
			task.threats.push_back(ActorData.collect(threat))

		## Enemies this actor will attack (sorted by aggro)
		var targets = threats
		if actor.Behaviour is ActorBehaviourWorldControlled behaviour:
			targets.sort_custom(func(a, b):
				var indexOfA = behaviour.Ranking.find_custom(func(rank: ActorBehaviourWorldControlled.RankedTarget): return rank.Target == a)
				var indexOfB = behaviour.Ranking.find_custom(func(rank: ActorBehaviourWorldControlled.RankedTarget): return rank.Target == b)
				return indexOfA < indexOfB and indexOfA != -1
			)
		for target in targets:
			task.targets.push_back(ActorData.collect(target))

		return task

	class ActorData:
		var threat: float
		var globalPosition: Vector3
		var physicalSize: float
		var ignoredWalls: Array[PhysicsFieldObstacle]

		static func collect(actor: Actor) -> ActorData:
			var data = ActorData.new()
			data.threat = actor.Stats.ThreatCurrent
			data.physicalSize = actor.PhysicalSize
			data.globalPosition = actor.global_position
			data.ignoredWalls = PropWall.GetIgnoredWallRidsAt(PropWall.collectBehaviourMapTaskData(), actor.global_position, actor.PhysicalSize)
			return data

	class WallData:
		var wallName: String
		var coverValue: float
		var canBeUsedAsCover: float
		var globalPosition: Vector3
		var boundingCircleRadius: float
		var segmentPositions: Array[Vector3]
		var obstacle: PhysicsFieldObstacle

		func _to_string() -> String:
			return "<MapTask.WallData %s>"%wallName

static func createActorValueMap(actor: Actor) -> FloatFieldMap:
	var task = await MapTask.collect(actor)

	var timer = PerformanceUtils.startMeasure("AI evaluation for %s"%actor)
	var coverPromise = Promise.run(func(): return _dispatchCreateActorCoverMapTask(task))
	var lineOfSightPromise = Promise.run(func(): return _dispatchCreateActorLineOfSightMapTask(task))
	var proximityPromise = Promise.run(func(): return _dispatchCreateActorProximityMapTask(task))

	var coverMap = await coverPromise.toResolve() as FloatFieldMap
	var lineOfSightMap = await lineOfSightPromise.toResolve() as FloatFieldMap
	var proximityMap = await proximityPromise.toResolve() as FloatFieldMap
	timer.endMeasure()

	return coverMap.leftMerge(lineOfSightMap).leftMerge(proximityMap)

static func createActorCoverMap(actor: Actor) -> FloatFieldMap:
	var task = await MapTask.collect(actor)
	return await Promise.run(func(): return _dispatchCreateActorCoverMapTask(task)).done

static func createActorLineOfSightMap(actor: Actor) -> FloatFieldMap:
	var task = await MapTask.collect(actor)
	return await Promise.run(func(): return _dispatchCreateActorLineOfSightMapTask(task)).done

static func createActorProximityMap(actor: Actor) -> FloatFieldMap:
	var task = await MapTask.collect(actor)
	return await Promise.run(func(): return _dispatchCreateActorProximityMapTask(task)).done

static func _dispatchCreateActorLineOfSightMapTask(task: MapTask) -> FloatFieldMap:
	var values: Dictionary[Vector2i, float]
	for point in task.navmeshSample.points:
		var coverScore = evaluateLineOfSightScoreAtLocation(task, point)
		var cell = toCellCoordinates(point, task.gridSize)
		values[cell] = coverScore
	return _produceFloatFieldMap(task, values)

static func _dispatchCreateActorCoverMapTask(task: MapTask) -> FloatFieldMap:
	var values: Dictionary[Vector2i, float]
	for point in task.navmeshSample.points:
		var coverScore = evaluateCoverScoreAtLocation(task, point)
		var cell = toCellCoordinates(point, task.gridSize)
		values[cell] = coverScore
	return _produceFloatFieldMap(task, values)

static func _dispatchCreateActorProximityMapTask(task: MapTask) -> FloatFieldMap:
	var values: Dictionary[Vector2i, float]
	for point in task.navmeshSample.points:
		var proximityScore = evaluateProximityScoreAtLocation(task, point)
		var cell = toCellCoordinates(point, task.gridSize)
		values[cell] = proximityScore
	return _produceFloatFieldMap(task, values)

static func _produceFloatFieldMap(task: MapTask, values: Dictionary[Vector2i, float]) -> FloatFieldMap:
	var neighbourDist = task.actor.physicalSize * 2 - 0.05
	var neighbourDistSquared = neighbourDist ** 2
	var neighboursOfCell: Dictionary[Vector2i, Array[Vector3]]
	var weightsOfNeighbours: Dictionary[Vector2i, Array[float]]
	for point in task.navmeshSample.points:
		var cell = toCellCoordinates(point, task.gridSize)
		if not values.has(cell):
			continue
		var validNeighbours: Array[Vector3]
		var neighbourWeights: Array[float]
		for other in task.navmeshSample.points:
			if point == other:
				continue
			var distSquared = other.distance_squared_to(point)
			if distSquared < neighbourDistSquared:
				validNeighbours.push_back(other)
				neighbourWeights.push_back(neighbourDist - sqrt(distSquared))
		neighboursOfCell[cell] = validNeighbours
		weightsOfNeighbours[cell] = neighbourWeights

	## Gaussian blur (kind of) the point values
	for y in range(WEIGHT_BLUR_ITERATIONS):
		var nextValues: Dictionary[Vector2i, float]
		for point in task.navmeshSample.points:
			var cell = toCellCoordinates(point, task.gridSize)
			if not values.has(cell):
				continue
			var validNeighbours = neighboursOfCell[cell]
			var neighbourWeights = weightsOfNeighbours[cell]

			var weightSum = 1.0
			var acc = values[cell]
			for i in range(validNeighbours.size()):
				var neighbourValue = values[toCellCoordinates(validNeighbours[i], task.gridSize)]
				var w = neighbourWeights[i]
				acc += neighbourValue * w
				weightSum += w
			nextValues[cell] = acc / weightSum

		values = nextValues

	## Produce a sorted array to easily access the best positions
	var scored: Array[FloatFieldMap.ScoredPoint] = []
	for point in task.navmeshSample.points:
		var cell = toCellCoordinates(point, task.gridSize)
		scored.push_back(FloatFieldMap.ScoredPoint.new(cell, point, values[cell]))
	scored.sort_custom(func(a, b):
		return a.score > b.score
	)

	return FloatFieldMap.Build(values, task.navmeshSample.points, task.gridSize, scored)

static func toCellCoordinates(point: Vector3, gridSize: float) -> Vector2i:
	return Vector2i(int(floor(point.x / gridSize)), int(floor(point.z / gridSize)))

static func evaluateCoverScoreAtLocation(task: MapTask, candidate: Vector3) -> float:
	var threshold = pow(task.actor.physicalSize * 3, 2)
	var wallSeen = false
	var minWallValue = INF
	for wall in task.allWalls:
		var adjustedCoverValue = wall.coverValue if wall.canBeUsedAsCover else 0.67
		if adjustedCoverValue >= minWallValue:
			continue
		var minimalDistanceSquared = pow(wall.boundingCircleRadius + wall.boundingCircleRadius, 2)
		if wall.globalPosition.distance_to(candidate) > minimalDistanceSquared:
			continue
		for segment in wall.segmentPositions:
			if segment.distance_squared_to(candidate) < threshold:
				wallSeen = true
				minWallValue = adjustedCoverValue
				break
	if not wallSeen:
		minWallValue = -1
	return minWallValue * task.weightCover / 2.0


static func evaluateProximityScoreAtLocation(task: MapTask, candidate: Vector3) -> float:
	var score = 0.0
	if task.weightDistanceToMove != 0.0:
		var straightDistance = task.actor.globalPosition.distance_to(candidate)
		var distanceScore = maxf(-1.0, -straightDistance / 10.0)
		score += distanceScore * task.weightDistanceToMove * 0.5

		var path = NavigationUtils.getPath(task.navigationMapRid, task.actor.globalPosition, candidate)
		var length = NavigationUtils.getPathLength(path)
		var walkingScore = maxf(-1.0, -length / 10.0)
		score += walkingScore * task.weightDistanceToMove * 0.5

	if task.weightProximityToAllies != 0.0 and task.allies.size() > 0:
		var distToClosestAlly = INF
		for ally in task.allies:
			#var dist = ally.globalPosition.distance_to(candidate)
			var path = NavigationUtils.getPath(task.navigationMapRid, candidate, ally.globalPosition)
			var dist = NavigationUtils.getPathLength(path)
			if dist < distToClosestAlly:
				distToClosestAlly = dist
		var allyScore = maxf(0.0, 1.0 - distToClosestAlly / maxf(0.1, task.weightProximityToAlliesFalloffMeters))
		score += allyScore * task.weightProximityToAllies

	if task.weightAvoidMeleeRange != 0.0 and task.threats.size() > 0:
		var meleeRangeScore = 0.0
		for enemy in task.threats:
			var dist = enemy.globalPosition.distance_to(candidate)
			var threshold = 3.0 + enemy.physicalSize * 2.0
			meleeRangeScore += maxf(0.0, 1.0 - dist / threshold)
		score -= meleeRangeScore * task.weightAvoidMeleeRange

	if (task.weightProximityToEnemies != 0.0 or task.weightOutOfFight != 0.0) and task.targets.size() > 0:
		var closestEnemy: MapTask.ActorData
		var distToClosestEnemy = INF
		for enemy in task.targets:
			#var dist = enemy.globalPosition.distance_to(candidate)
			var path = NavigationUtils.getPath(task.navigationMapRid, candidate, enemy.globalPosition)
			var dist = NavigationUtils.getPathLength(path)
			if dist < distToClosestEnemy:
				closestEnemy = enemy
				distToClosestEnemy = dist
		var enemyScore = maxf(0.0, 1.0 - distToClosestEnemy / maxf(0.1, task.weightProximityToEnemiesFalloffMeters))
		score += enemyScore * task.weightProximityToEnemies * closestEnemy.threat

		var outOfFightScore = maxf(0.0, (distToClosestEnemy - task.weightOutOfFightMinDistance) / 5.0)
		score -= outOfFightScore * task.weightOutOfFight

	return score

static func evaluateLineOfSightScoreAtLocation(task: MapTask, candidate: Vector3) -> float:
	if task.targets.is_empty() and task.threats.is_empty():
		return 0.0

	var score = 0.0

	## Agent shooting at the focused targets
	var currentShot = ShotContext.new()
	currentShot.task = task
	var ignoredWallsAtCandidate = PropWall.GetIgnoredWallRidsAt(task.ignorableWalls, candidate, task.actor.physicalSize)
	for skill in task.actorOffensiveSkills:
		if task.weightHasShot == 0.0:
			break

		var skillMax = 0.0
		for enemy in task.targets:
			if enemy.threat <= 0.0 or skill.BehaviourUsagePreference * enemy.threat < skillMax:
				continue
			currentShot.from = candidate
			currentShot.to = enemy.globalPosition
			currentShot.shooter = task.actor
			currentShot.target = enemy
			currentShot.ignoredWalls = ignoredWallsAtCandidate
			skillMax = max(scoreSkillUsable(currentShot, skill), skillMax)
		score += skillMax * task.weightHasShot

	## Enemies shooting at the agent
	for enemy in task.threats:
		if enemy.threat <= 0.0 or task.weightHasShot == 0.0:
			break
		currentShot.from = enemy.globalPosition
		currentShot.to = candidate
		currentShot.shooter = enemy
		currentShot.target = task.actor
		currentShot.ignoredWalls = enemy.ignoredWalls
		if canBeShotBy(currentShot):
			score -= task.weightAvoidLineOfSight * enemy.threat

	return score

class ShotContext:
	var task: MapTask
	var from: Vector3
	var to: Vector3
	var shooter: MapTask.ActorData
	var target: MapTask.ActorData
	var ignoredWalls: Array[PhysicsFieldObstacle]

	var flatDistance: float:
		get:
			return Vector2(to.x - from.x, to.z - from.z).length()

static func scoreSkillUsable(shot: ShotContext, skill: SkillDefinition) -> float:
	if shot.flatDistance > skill.TargetingMaxRange + shot.shooter.physicalSize:
		return 0.0
	if skill.BehaviourRequireLineOfSight:
		if not hasLineOfSight(shot):
			return 0.0
	return skill.BehaviourUsagePreference

static func hasLineOfSight(shot: ShotContext) -> bool:
	var query = PhysicsFieldRaycastQuery.new()
	query.width = BEAM_WIDTH
	query.origin = shot.from
	query.target = shot.to
	query.collision_mask = CollisionLayer.FULL_COVER | CollisionLayer.HIGH_COVER | CollisionLayer.LOW_COVER
	query.exclude = shot.ignoredWalls
	var result = shot.task.physicsField.raycast_query(query)
	return not result.has_hits

static func canBeShotBy(shot: ShotContext) -> bool:
	var mask = CollisionLayer.FULL_COVER | CollisionLayer.HIGH_COVER | CollisionLayer.LOW_COVER
	var center = shot.to
	var radius = shot.target.physicalSize

	var targets: Array[Vector3] = [center]

	var outlineCount = 4
	for i in outlineCount:
		var angle = TAU * float(i) / float(outlineCount)
		targets.append(center + Vector3(cos(angle) * radius, 0.0, sin(angle) * radius))

	var midCount = 3
	var midRadius = radius * 0.5
	for i in midCount:
		var angle = TAU * float(i) / float(midCount)
		targets.append(center + Vector3(cos(angle) * midRadius, 0.0, sin(angle) * midRadius))

	for point in targets:
		var query = PhysicsFieldRaycastQuery.new()
		query.width = BEAM_WIDTH
		query.origin = shot.from
		query.target = point
		query.collision_mask = mask
		query.exclude = shot.ignoredWalls
		var result = shot.task.physicsField.raycast_query(query)
		if not result.has_hits:
			return true

	return false
#endregion

#region Helpers
static func findAllies(actor: Actor) -> Array[Actor]:
	var result: Array[Actor] = []
	for other in Actor.Repository.Alive.List:
		if other == actor or not is_instance_valid(other) or not other.isAlive:
			continue
		if not ActorUtils.isAlliedTo(other, actor):
			continue
		if NavigationUtils.isPointEverReachable(other.navigator.agent.get_navigation_map(), other.global_position, actor.PhysicalSize):
			result.push_back(other)
	return result

static func findEnemies(actor: Actor) -> Array[Actor]:
	var result: Array[Actor] = []
	for other in Actor.Repository.Alive.List:
		if other == actor or not is_instance_valid(other) or not other.isAlive:
			continue
		if not ActorUtils.isHostileTo(other, actor):
			continue
		if NavigationUtils.isPointEverReachable(other.navigator.agent.get_navigation_map(), other.global_position, actor.PhysicalSize):
			result.push_back(other)
	return result

static func gatherAttackSkills(actor: Actor) -> Array[SkillDefinition]:
	var out: Array[SkillDefinition] = []
	for i in 16:
		var skill = actor.Skills.GetByIndex(i)
		if skill == null:
			continue
		var hasDamage: bool = skill.Definition.Telegraphs.any(func(t): return t.HealthThreat > 0)
		if hasDamage:
			out.push_back(skill.Definition)
	return out
#endregion
