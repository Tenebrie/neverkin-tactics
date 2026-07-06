class_name FloatFieldMap

var Resolution: float = 0.25
var Data: Dictionary[Vector2i, float]
var Points: Array[Vector3]

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

static func Build(data: Dictionary[Vector2i, float], points: Array[Vector3], resolution: float) -> FloatFieldMap:
	var map = FloatFieldMap.new()
	map.Data = data
	map.Points = points
	map.Resolution = resolution
	return map
