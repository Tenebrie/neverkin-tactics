@tool
extends Node3D
class_name SkillStealTimeEffect

var system: ProjectileSystem

func _ready() -> void:
	system = ProjectileSystem.new()
	add_child(system)
	system.theme.trailSizeCurve = preload("./SkillStealTimeTrailCurve.tres")
	system.theme.trailColorGradient = preload("./SkillStealTimeTrailGradient.tres")
	system.theme.trailTimeSizeCurve = preload("./SkillStealTimeTrailTimeCurve.tres")
	system.theme.trailTimeColorGradient = preload("./SkillStealTimeTrailTimeGradient.tres")

func Play(target: Vector3, projectileCount: int, duration: float = 0.2) -> void:
	var def = ProjectileSystem.Definition.new()
	def.travelTime = duration
	def.arcSelector = func(_index: int) -> float: return randf_range(-1, 1)
	await system.play(global_position, target, def, projectileCount, 0.1)
