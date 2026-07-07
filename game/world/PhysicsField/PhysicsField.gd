class_name PhysicsFieldGD

const Math = preload("./Math.gd")

class Obstacle:
	var collisionLayer: int
	var aabb: Rect2
	var segments: Array[ObstacleSegment]
	var transform: Transform2D

class ObstacleSegment:
	var shape: PhysicsShape
	var transform: Transform2D
	var inverseFieldTransform: Transform2D

class State:
	var aabb: Rect2
	var obstacles: Array[Obstacle]

	func updateBoundingBox():
		if obstacles.is_empty():
			aabb = Rect2()
			return
		aabb = obstacles[0].aabb
		for i in range(1, obstacles.size()):
			aabb = aabb.merge(obstacles[i].aabb)

	func updateTransforms():
		for obstacle in obstacles:
			for segment in obstacle.segments:
				segment.inverseFieldTransform = (obstacle.transform * segment.transform).affine_inverse()

static func buildState():
	var state = State.new()
	state.obstacles = PropWall.collectPhysicsFieldObstaclesGD()
	state.updateBoundingBox()
	state.updateTransforms()
	return state


class RaycastQuery:
	var origin: Vector3
	var target: Vector3

class RaycastQueryResult:
	var hasHits:
		get:
			return hits.size() > 0
	var hits: Array[Hit]

	class Hit:
		var fraction: float
		var position: Vector3

static func raycastQuery(state: State, params: RaycastQuery) -> RaycastQueryResult:
	var result = RaycastQueryResult.new()
	var rayOrigin = Vector2(params.origin.x, params.origin.z)
	var rayTarget = Vector2(params.target.x, params.target.z)
	for obstacle in state.obstacles:
		if not Math.raycastHitsAabb(rayOrigin, rayTarget, obstacle.aabb):
			continue

		for segment in obstacle.segments:
			var fraction = Math.raycastAgainstShape(rayOrigin, rayTarget, segment.shape, segment.inverseFieldTransform)
			if fraction < 0:
				continue
			var hit = RaycastQueryResult.Hit.new()
			hit.fraction = fraction
			hit.position = params.origin + (params.target - params.origin) * fraction
			result.hits.push_back(hit)

	result.hits.sort_custom(func(a, b):
		return a.fraction < b.fraction
	)
	return result
