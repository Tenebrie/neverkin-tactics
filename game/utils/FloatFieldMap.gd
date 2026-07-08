class_name FloatFieldMap

var resolution: float = 0.25
var data: Dictionary[Vector2i, float]
var points: Array[Vector3]
var scoredPoints: Array[ScoredPoint]
var cellToScoredPoint: Dictionary[Vector2i, ScoredPoint]

func read(point: Vector3) -> float:
	var cell = toCellCoordinates(point)
	if data.has(cell):
		return data[cell]
	printerr("Unable to read field map at %s"%str(cell))
	return 0

func multiply(scalar: float) -> FloatFieldMap:
	for point in data:
		data[point] *= scalar
	for point in scoredPoints:
		point.score *= scalar
	return self

func leftMerge(other: FloatFieldMap) -> FloatFieldMap:
	if other.resolution != resolution:
		printerr("Unable to merge - resolution does not match (%f and %f)"%[resolution, other.resolution])
		return self

	for cell in data.keys():
		if other.data.has(cell):
			data[cell] += other.data[cell]

	for scoredPoint in scoredPoints:
		if other.cellToScoredPoint.has(scoredPoint.cell):
			scoredPoint.score += other.cellToScoredPoint[scoredPoint.cell].score

	return self

func toCellCoordinates(point: Vector3) -> Vector2i:
	return Vector2i(int(floor(point.x / resolution)), int(floor(point.z / resolution)))

static func Empty() -> FloatFieldMap:
	return FloatFieldMap.new()

static func Build(data: Dictionary[Vector2i, float], points: Array[Vector3], resolution: float, scoredPoints: Array[ScoredPoint]) -> FloatFieldMap:
	var map = FloatFieldMap.new()
	map.data = data
	map.points = points
	map.resolution = resolution
	map.scoredPoints = scoredPoints
	for point in scoredPoints:
		map.cellToScoredPoint[point.cell] = point
	return map

class ScoredPoint:
	var cell: Vector2i
	var point: Vector3
	var score: float
	func _init(cell: Vector2i, point: Vector3, score: float) -> void:
		self.cell = cell
		self.point = point
		self.score = score
