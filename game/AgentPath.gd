class_name AgentPath
extends Node3D

@export var LineColor: Color:
	get:
		return material.albedo_color
	set(value):
		material.albedo_color = value

@export var LineWidth := 0.02
@export var HeightOffset := -0.01

var meshInstance: MeshInstance3D
var immediateMesh: ImmediateMesh
var material: StandardMaterial3D = StandardMaterial3D.new()
var points: PackedVector3Array

func _ready() -> void:
	top_level = true
	global_position = Vector3.ZERO

	immediateMesh = ImmediateMesh.new()
	meshInstance = MeshInstance3D.new()
	meshInstance.mesh = immediateMesh
	meshInstance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(meshInstance)

	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color = Color(0.3, 0.8, 1.0, 0.5)
	meshInstance.material_override = material

func SetPath(path: PackedVector3Array, currentPosition: Vector3) -> void:
	points = cleanPoints(buildVisiblePoints(path, currentPosition))
	rebuild()

func cleanPoints(raw: PackedVector3Array) -> PackedVector3Array:
	var result := PackedVector3Array()
	var minDist := 0.02
	for p in raw:
		if result.size() == 0:
			result.append(p)
			continue
		if flat(p - result[result.size() - 1]).length() >= minDist:
			result.append(p)
	if result.size() > 0 and result[result.size() - 1] != raw[raw.size() - 1]:
		result.append(raw[raw.size() - 1])
	return result

func ClearPath() -> void:
	points = PackedVector3Array()
	rebuild()

func GetLength() -> float:
	var total := 0.0
	for i in points.size() - 1:
		total += (points[i + 1] - points[i]).length()
	return total

func buildVisiblePoints(path: PackedVector3Array, currentPosition: Vector3) -> PackedVector3Array:
	var result := PackedVector3Array()
	if path.size() < 1:
		return result

	var pos := flat(currentPosition)
	var bestDist := INF
	var startIndex := path.size()

	for i in path.size() - 1:
		var a := flat(path[i])
		var b := flat(path[i + 1])
		var ab := b - a
		var lenSq := ab.length_squared()
		var t := 0.0
		if lenSq > 0.0000001:
			t = clampf((pos - a).dot(ab) / lenSq, 0.0, 1.0)
		var closest := a + ab * t
		var d := pos.distance_squared_to(closest)
		if d < bestDist:
			bestDist = d
			startIndex = i + 1

	result.append(currentPosition)
	for i in range(startIndex, path.size()):
		result.append(path[i])
	return result

func flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0.0, v.z)

func rebuild() -> void:
	immediateMesh.clear_surfaces()
	var count := points.size()
	if count < 2:
		return

	var half := LineWidth * 0.5
	var up := Vector3.UP
	var lift := up * HeightOffset
	var miterLimit := 2.0

	var offsets: Array[Vector3] = []
	offsets.resize(count)
	for i in count:
		var inDir := Vector3.ZERO
		var outDir := Vector3.ZERO
		if i > 0:
			inDir = flat(points[i] - points[i - 1])
		if i < count - 1:
			outDir = flat(points[i + 1] - points[i])
		inDir = inDir.normalized() if inDir.length_squared() > 0.0000001 else Vector3.ZERO
		outDir = outDir.normalized() if outDir.length_squared() > 0.0000001 else Vector3.ZERO
		if inDir == Vector3.ZERO:
			inDir = outDir
		if outDir == Vector3.ZERO:
			outDir = inDir

		var nIn := up.cross(inDir)
		var nOut := up.cross(outDir)
		var miter := nIn + nOut
		if miter.length_squared() < 0.0000001:
			miter = nOut
		miter = miter.normalized()

		var cosHalf := miter.dot(nOut.normalized())
		var lineScale := 1.0 / maxf(absf(cosHalf), 1.0 / miterLimit)
		offsets[i] = miter * half * lineScale

	immediateMesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, material)
	for i in count - 1:
		var a := points[i] + lift
		var b := points[i + 1] + lift
		var oa := offsets[i]
		var ob := offsets[i + 1]

		addVertex(a + oa)
		addVertex(b + ob)
		addVertex(b - ob)
		addVertex(a + oa)
		addVertex(b - ob)
		addVertex(a - oa)
	immediateMesh.surface_end()

func addVertex(v: Vector3) -> void:
	immediateMesh.surface_set_color(LineColor)
	immediateMesh.surface_add_vertex(v)
