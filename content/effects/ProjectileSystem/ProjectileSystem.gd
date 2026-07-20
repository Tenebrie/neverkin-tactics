extends Node
class_name ProjectileSystem

class ProjectileTheme:
	@export var trailSizeCurve: Curve = preload("res://content/effects/ProjectileSystem/defaultTheme/DefaultTrailCurve.tres")
	@export var trailColorGradient: Gradient = preload("res://content/effects/ProjectileSystem/defaultTheme/DefaultTrailGradient.tres")
	@export var trailTimeSizeCurve: Curve = preload("res://content/effects/ProjectileSystem/defaultTheme/DefaultTrailTimeCurve.tres")
	@export var trailTimeColorGradient: Gradient = preload("res://content/effects/ProjectileSystem/defaultTheme/DefaultTrailTimeGradient.tres")

class Definition:
	## Number of points that forms the trail; higher is better, but more performance expensive
	@export var pointCount = 50
	## Tween parameters
	@export var tweenEaseType: Tween.EaseType = Tween.EASE_OUT
	@export var tweenTransitionType: Tween.TransitionType = Tween.TRANS_SINE
	## Deviation from straight line, in meters at half-way point
	@export var arc = 0.0
	@export var arcSelector = func(_index: int) -> float: return arc
	## Trail width, in meters
	@export var width = 0.05
	@export var widthSelector = func(_index: int) -> float: return width
	## Time it takes the trail to reach the target, in seconds
	@export var travelTime = 0.2
	@export var travelTimeSelector = func(_index: int) -> float: return travelTime
	## Time it takes for each trail segment to dissipate, in seconds
	@export var lingerTime = 0.7
	@export var lingerTimeSelector = func(_index: int) -> float: return lingerTime
	## Height at which the trail travels
	@export var renderHeight = RenderHeight.SkillTrails

static func Create(parent: Node, lifetime = 30.0) -> ProjectileSystem:
	var system = ProjectileSystem.new()
	parent.add_child(system)
	(Engine.get_main_loop() as SceneTree).create_timer(lifetime).timeout.connect(func():
		system.queue_free()
	)
	return system

var theme = ProjectileTheme.new()

func play(origin: Variant, target: Variant, def: Definition = Definition.new(), count: int = 1, timeBetweenShots: float = 0.0) -> void:
	if origin is Node3D:
		origin = origin.global_position
	if target is Node3D:
		target = target.global_position
	origin.y = def.renderHeight
	target.y = def.renderHeight
	for i in count:
		_createProjectileTrail(theme, origin, target, def, i)
		if timeBetweenShots > 0.0:
			await get_tree().create_timer(timeBetweenShots).timeout

func _createProjectileTrail(theme: ProjectileTheme, from: Vector3, to: Vector3, def: Definition, index: int) -> void:
	var arc = def.arcSelector.call(index)
	var travelTime = def.travelTimeSelector.call(index)
	var lingerTime = def.lingerTimeSelector.call(index)
	var trail = VaporTrail.new()
	trail.position = from
	trail.size = def.widthSelector.call(index)
	trail.emitting = true
	trail.num_points = def.pointCount
	trail.update_interval = lingerTime / def.pointCount
	trail.material = preload("res://addons/vaportrail/example/SmokyMaterial.tres")
	trail.size_curve = theme.trailSizeCurve
	trail.color_gradient = theme.trailColorGradient
	trail.time_curve = theme.trailTimeSizeCurve
	trail.time_color_gradient = theme.trailTimeColorGradient
	add_child(trail)

	var direction = (from - to).normalized()
	var sideways = Vector3(-direction.z, 0.0, direction.x)

	var tween = create_tween()
	tween.tween_method(func(t: float) -> void:
		var pos = from.lerp(to, t)
		pos -= sideways * arc * 4.0 * t * (1.0 - t)
		trail.position = pos
		trail.current_time = t
	, 0.0, 1.0, travelTime).set_ease(def.tweenEaseType).set_trans(def.tweenTransitionType)

	tween.tween_callback(func() -> void:
		trail.emitting = false
	)

	await get_tree().create_timer(travelTime + lingerTime).timeout
	trail.queue_free()
