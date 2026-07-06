class_name FloatFieldMap

var Resolution: float = 0.25
var Data: Dictionary[Vector2i, float]
var Points: Array[Vector3]
var ScoredPoints: Array[ScoredPoint]

func Read(point: Vector3) -> float:
	var cell = toCellCoordinates(point)
	if Data.has(cell):
		return Data[cell]
	printerr("Unable to read field map at %s"%str(cell))
	return 0

func toCellCoordinates(point: Vector3) -> Vector2i:
	return Vector2i(int(floor(point.x / Resolution)), int(floor(point.z / Resolution)))

static func Empty() -> FloatFieldMap:
	return FloatFieldMap.new()

static func Build(data: Dictionary[Vector2i, float], points: Array[Vector3], resolution: float, scoredPoints: Array[ScoredPoint]) -> FloatFieldMap:
	var map = FloatFieldMap.new()
	map.Data = data
	map.Points = points
	map.Resolution = resolution
	map.ScoredPoints = scoredPoints
	return map

class ScoredPoint:
	var Point: Vector3
	var Score: float
	func _init(point: Vector3, score: float) -> void:
		Point = point
		Score = score
