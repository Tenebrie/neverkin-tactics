extends Area3D
class_name MouseArea3D

signal mouseEnteredImmediate
signal mouseExitedImmediate

var isHovered = false
var rayShape: Shape3D = null

static var registeredAreas: Array[MouseArea3D] = []
static var hoveredArea: MouseArea3D = null

func _init() -> void:
	ready.connect(_onReady)
	tree_exiting.connect(_onTreeExiting)

func _onReady() -> void:
	var collisionShape = _findCollisionShape()
	if collisionShape != null:
		rayShape = collisionShape.shape
	registeredAreas.append(self)

func _onTreeExiting() -> void:
	registeredAreas.erase(self)
	if hoveredArea == self:
		hoveredArea = null

func _findCollisionShape() -> CollisionShape3D:
	for child in get_children():
		if child is CollisionShape3D:
			return child
	return null

static func updateHoverStates() -> void:
	var tree = Engine.get_main_loop() as SceneTree
	if tree == null or Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
		return
	var viewport = tree.root.get_viewport()
	var camera = viewport.get_camera_3d()
	if camera == null:
		return
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		return

	var nowHovered: MouseArea3D = null

	# UI obstruction — a Control under the cursor blocks 3D hover
	if viewport.gui_get_hovered_control() == null:
		var mousePos = viewport.get_mouse_position()
		var from = camera.project_ray_origin(mousePos)
		var dir = camera.project_ray_normal(mousePos)

		var nearest = INF
		for area in registeredAreas:
			if area.rayShape == null:
				continue
			var dist = area._rayDistance(from, dir)
			if dist >= 0.0 and dist < nearest:
				nearest = dist
				nowHovered = area

	if nowHovered == hoveredArea:
		return
	if hoveredArea != null:
		hoveredArea._setHovered(false)
	hoveredArea = nowHovered
	if hoveredArea != null:
		hoveredArea._setHovered(true)


# Ray-vs-shape against THIS FRAME's transform. Returns hit distance along dir, or -1.
func _rayDistance(from: Vector3, dir: Vector3) -> float:
	var xform = global_transform
	# transform ray into shape-local space
	var inv = xform.affine_inverse()
	var localFrom = inv * from
	var localDir = (inv.basis * dir).normalized()

	if rayShape is SphereShape3D:
		return _raySphere(localFrom, localDir, rayShape.radius)
	elif rayShape is BoxShape3D:
		return _rayBox(localFrom, localDir, rayShape.size * 0.5)
	elif rayShape is CapsuleShape3D:
		return _rayCapsule(localFrom, localDir, rayShape.radius, rayShape.height)
	return -1.0


func _setHovered(value: bool) -> void:
	if value == isHovered:
		return
	isHovered = value
	if value:
		mouseEnteredImmediate.emit()
	else:
		mouseExitedImmediate.emit()


# --- analytic intersections in shape-local space ---

func _raySphere(o: Vector3, d: Vector3, r: float) -> float:
	var b = o.dot(d)
	var c = o.dot(o) - r * r
	var disc = b * b - c
	if disc < 0.0:
		return -1.0
	var sq = sqrt(disc)
	var t = -b - sq
	if t < 0.0:
		t = -b + sq
	return t if t >= 0.0 else -1.0

func _rayBox(o: Vector3, d: Vector3, half: Vector3) -> float:
	var tmin = -INF
	var tmax = INF
	for i in 3:
		if absf(d[i]) < 1e-8:
			if o[i] < -half[i] or o[i] > half[i]:
				return -1.0
		else:
			var inv = 1.0 / d[i]
			var t1 = (-half[i] - o[i]) * inv
			var t2 = (half[i] - o[i]) * inv
			if t1 > t2:
				var tmp = t1; t1 = t2; t2 = tmp
			tmin = maxf(tmin, t1)
			tmax = minf(tmax, t2)
			if tmin > tmax:
				return -1.0
	return tmin if tmin >= 0.0 else (tmax if tmax >= 0.0 else -1.0)

# Capsule aligned on local Y (Godot convention), cylinder height excludes the two hemisphere caps
func _rayCapsule(o: Vector3, d: Vector3, r: float, height: float) -> float:
	var halfCyl = maxf(height * 0.5 - r, 0.0)
	var best = INF

	# infinite cylinder around Y
	var ox = o.x; var oz = o.z
	var dx = d.x; var dz = d.z
	var a = dx * dx + dz * dz
	if a > 1e-8:
		var b = 2.0 * (ox * dx + oz * dz)
		var c = ox * ox + oz * oz - r * r
		var disc = b * b - 4.0 * a * c
		if disc >= 0.0:
			var sq = sqrt(disc)
			for t in [(-b - sq) / (2.0 * a), (-b + sq) / (2.0 * a)]:
				if t >= 0.0:
					var y = o.y + d.y * t
					if absf(y) <= halfCyl:
						best = minf(best, t)

	# two hemisphere caps
	for capY in [halfCyl, -halfCyl]:
		var co = o - Vector3(0, capY, 0)
		var bb = co.dot(d)
		var cc = co.dot(co) - r * r
		var dd = bb * bb - cc
		if dd >= 0.0:
			var s = sqrt(dd)
			for t in [-bb - s, -bb + s]:
				if t >= 0.0:
					var y = o.y + d.y * t
					if (capY > 0.0 and y >= halfCyl) or (capY < 0.0 and y <= -halfCyl):
						best = minf(best, t)

	return best if best != INF else -1.0
