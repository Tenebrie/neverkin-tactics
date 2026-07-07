static func raycastHitsAabb(origin: Vector2, target: Vector2, aabb: Rect2) -> bool:
	var boxMin = aabb.position
	var boxMax = aabb.end

	var entryFraction = 0.0
	var exitFraction = 1.0

	for axis in 2:
		var start = origin[axis]
		var travel = target[axis] - start

		var bandMin = boxMin[axis]
		var bandMax = boxMax[axis]

		if abs(travel) < 0.00001:
			if start < bandMin or start > bandMax:
				return false
		else:
			var toBandMin = (bandMin - start) / travel
			var toBandMax = (bandMax - start) / travel

			if toBandMin > toBandMax:
				var swap = toBandMin
				toBandMin = toBandMax
				toBandMax = swap

			entryFraction = max(entryFraction, toBandMin)
			exitFraction = min(exitFraction, toBandMax)

			if entryFraction > exitFraction:
				return false

	return true

static func raycastAgainstShape(origin: Vector2, target: Vector2, shape: PhysicsShape, inverseFieldTransform: Transform2D) -> float:
	var localOrigin = inverseFieldTransform * origin
	var localTarget = inverseFieldTransform * target
	if shape is PhysicsShape.Rect:
		return raycastAgainstLocalRect(localOrigin, localTarget, shape.size / 2)
	elif shape is PhysicsShape.Circle:
		return raycastAgainstLocalCircle(localOrigin, localTarget, shape.radius)
	return -1

static func raycastAgainstLocalRect(origin: Vector2, target: Vector2, halfSize: Vector2) -> float:
	var entryFraction = 0.0
	var exitFraction = 1.0

	for axis in 2:
		var start = origin[axis]
		var travel = target[axis] - start

		var bandMin = -halfSize[axis]
		var bandMax = halfSize[axis]

		if abs(travel) < 0.00001:
			if start < bandMin or start > bandMax:
				return -1.0
		else:
			var toMin = (bandMin - start) / travel
			var toMax = (bandMax - start) / travel

			if toMin > toMax:
				var swap = toMin; toMin = toMax; toMax = swap

			entryFraction = max(entryFraction, toMin)
			exitFraction = min(exitFraction, toMax)

			if entryFraction > exitFraction:
				return -1.0
	return entryFraction

static func raycastAgainstLocalCircle(origin: Vector2, target: Vector2, radius: float) -> float:
	var d = target - origin
	var f = origin

	var a = d.dot(d)
	var b = 2.0 * f.dot(d)
	var c = f.dot(f) - radius * radius

	if a < 0.00001:
		return 0.0 if c <= 0.0 else -1.0

	var discriminant = b * b - 4.0 * a * c
	if discriminant < 0.0:
		return -1.0

	var sqrtDisc = sqrt(discriminant)
	var f1 = (-b - sqrtDisc) / (2.0 * a)
	var f2 = (-b + sqrtDisc) / (2.0 * a)

	if f1 >= 0.0 and f1 <= 1.0:
		return f1
	if f2 >= 0.0 and f2 <= 1.0:
		return f2
	return -1.0
