extends Component
class_name ActorQuery

var AllLivingActors:
	get:
		return Builder.new(ActorUtils.flatPositionOf(parent)).exceptFor(Prop)

class Builder:
	var _currentPosition: Vector3
	var _currentList: Array[Actor] = Actor.Repository.Alive.List.slice(0)

	func _init(origin: Vector3) -> void:
		_currentPosition = origin

	func inRange(maxRange: float) -> Builder:
		var rangeSquared = maxRange ** 2
		_currentList = _currentList.filter(func(actor):
			return actor.global_position.distance_squared_to(_currentPosition) <= rangeSquared
		)
		return self

	func exceptFor(excluded: Variant) -> Builder:
		if excluded is Array excludedArray:
			_currentList = _currentList.filter(func(actor):
				return not excludedArray.has(actor)
			)
		elif excluded is Actor excludedActor:
			_currentList = _currentList.filter(func(actor):
				return actor != excludedActor
			)
		elif excluded is GDScript excludedClass:
			_currentList = _currentList.filter(func(actor):
				return not Utils.IsNodeDescendantOf(actor, excludedClass)
			)
		return self

	func withBuff(buff: GDScript[Buff]) -> Builder:
		_currentList = _currentList.filter(func(actor):
			return actor.buffs and actor.buffs.Has(buff)
		)
		return self

	func nearest() -> Actor:
		if _currentList.size() == 0:
			return null
		var nearest = _currentList[0]
		var nearestDist = nearest.global_position.distance_squared_to(_currentPosition)
		for candidate in _currentList.slice(1):
			var candidateDist = candidate.global_position.distance_squared_to(_currentPosition)
			if candidateDist < nearestDist:
				nearest = candidate
				nearestDist = candidateDist
		return nearest

	func collect() -> Array[Actor]:
		return _currentList
