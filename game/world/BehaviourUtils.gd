extends Node
class_name BehaviourUtils

const BEAM_WIDTH: float = 0.1

#region Cover Check
class MapTask:
	var navmeshSample: NavmeshSampler.NavmeshSample
	var physicsField: PhysicsField
	var actorOffensiveSkills: Array[SkillDefinition]
	var gridSize: float

	var weightHasShot = 1.0
	var weightAvoidLineOfSight = 1.0

	var actor: ActorData
	var targets: Array[ActorData]
	var threats: Array[ActorData]
	var ignorableWalls: Array[WallData]

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
		var globalPosition: Vector3
		var boundingCircleRadius: float
		var segmentPositions: Array[Vector3]
		var obstacle: PhysicsFieldObstacle

class SignalBox:
	signal done(map: FloatFieldMap)

static func CreateActorCoverMap(actor: Actor) -> FloatFieldMap:
	## Collect interesting points to evaluate
	var gridSize = 0.25
	var start = Time.get_ticks_usec()
	var navmeshSample = await NavmeshSampler.CollectNavmeshPoints(actor, gridSize, 1.0, 0.0)
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

	var field = PhysicsField.new()
	field.obstacles = PropWall.collectPhysicsFieldObstacles()

	var task = MapTask.new()
	task.navmeshSample = navmeshSample
	task.physicsField = field
	task.gridSize = gridSize
	task.actor = MapTask.ActorData.collect(actor)
	task.actorOffensiveSkills = BehaviourUtils.gatherAttackSkills(actor)
	task.ignorableWalls = PropWall.collectBehaviourMapTaskData()
	for threat in threats:
		task.threats.push_back(MapTask.ActorData.collect(threat))
	for target in targets:
		task.targets.push_back(MapTask.ActorData.collect(target))
	task.weightHasShot = 1.0
	task.weightAvoidLineOfSight = 1.0
	if actor.Behaviour is ActorBehaviourWorldControlled behaviour:
		task.weightHasShot = behaviour.WeightHasShot
		task.weightAvoidLineOfSight = behaviour.WeightAvoidLineOfSight

	var signalBox = SignalBox.new()
	WorkerThreadPool.add_task(func():
		var sample = dispatchCreateActorCoverMap(task)
		signalBox.done.emit.call_deferred(sample)
	)
	var data: FloatFieldMap = await signalBox.done
	return data

static func dispatchCreateActorCoverMap(task: MapTask) -> FloatFieldMap:
	var values: Dictionary[Vector2i, float]
	## Populate initial values
	var start = Time.get_ticks_usec()
	for point in task.navmeshSample.points:
		var coverScore = EvaluateCoverScoreAtLocation(task, point)
		var cell = toCellCoordinates(point, task.gridSize)
		values[cell] = coverScore
	var elapsed = Time.get_ticks_usec() - start
	print("- Collecting initial values: %.2f ms" % [elapsed / 1000.0])

	## Find each point's neighbours
	start = Time.get_ticks_usec()
	var neighbourDist = pow(task.actor.physicalSize * 2 - 0.05, 2)
	var neighboursOfCell: Dictionary[Vector2i, Array[Vector3]]
	for point in task.navmeshSample.points:
		var cell = toCellCoordinates(point, task.gridSize)
		if not values.has(cell):
			continue
		var validNeighbours: Array[Vector3]
		for other in task.navmeshSample.points:
			if other.distance_squared_to(point) < neighbourDist and point != other:
				validNeighbours.push_back(other)
		neighboursOfCell[cell] = validNeighbours
	elapsed = Time.get_ticks_usec() - start
	print("- Collecting neighbours: %.2f ms" % [elapsed / 1000.0])

	## Gaussian blur (kind of) the point values
	start = Time.get_ticks_usec()
	for i in range(3):
		var nextValues: Dictionary[Vector2i, float]
		for point in task.navmeshSample.points:
			var cell = toCellCoordinates(point, task.gridSize)
			if not values.has(cell):
				continue
			nextValues[cell] = values[cell] * 0.5
			var validNeighbours = neighboursOfCell[cell]
			for neighbour in validNeighbours:
				var neighbourValue = values[toCellCoordinates(neighbour, task.gridSize)]
				nextValues[cell] += neighbourValue / validNeighbours.size() / 2.0

		values = nextValues
		nextValues = {}
	elapsed = Time.get_ticks_usec() - start
	print("- Applying blur: %.2f ms" % [elapsed / 1000.0])

	## Produce a sorted array to easily access the best positions
	start = Time.get_ticks_usec()
	var scored: Array[FloatFieldMap.ScoredPoint] = []
	for point in task.navmeshSample.points:
		scored.push_back(FloatFieldMap.ScoredPoint.new(point, values[toCellCoordinates(point, task.gridSize)]))
	scored.sort_custom(func(a, b):
		return a.Score > b.Score
	)
	elapsed = Time.get_ticks_usec() - start
	print("- Sorting points: %.2f ms" % [elapsed / 1000.0])

	return FloatFieldMap.Build(values, task.navmeshSample.points, task.gridSize, scored)

static func toCellCoordinates(point: Vector3, gridSize: float) -> Vector2i:
	return Vector2i(int(floor(point.x / gridSize)), int(floor(point.z / gridSize)))

static func EvaluateCoverScoreAtLocation(task: MapTask, candidate: Vector3) -> float:
	if task.targets.is_empty() and task.threats.is_empty():
		return 0.0

	var score = 0.0

	## Agent shooting at the focused targets
	var currentShot = ShotContext.new()
	currentShot.task = task
	var ignoredWallsAtCandidate = PropWall.GetIgnoredWallRidsAt(task.ignorableWalls, candidate, task.actor.physicalSize)
	for enemy in task.targets:
		currentShot.from = candidate
		currentShot.to = enemy.globalPosition
		currentShot.shooter = task.actor
		currentShot.target = enemy
		currentShot.ignoredWalls = ignoredWallsAtCandidate
		for skill in task.actorOffensiveSkills:
			score += scoreSkillUsable(currentShot, skill) * task.weightHasShot

	## Enemies shooting at the agent
	for enemy in task.threats:
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
	var query = PhysicsFieldRaycastQuery.new()
	query.width = BEAM_WIDTH
	query.origin = shot.from
	query.target = shot.to
	query.collision_mask = CollisionLayer.FULL_COVER | CollisionLayer.HIGH_COVER | CollisionLayer.LOW_COVER
	query.exclude = shot.ignoredWalls
	var result = shot.task.physicsField.raycast_query(query)
	return not result.has_hits
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
