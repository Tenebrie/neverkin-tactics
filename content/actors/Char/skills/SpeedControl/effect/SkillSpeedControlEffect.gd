@tool
extends Node3D
class_name SkillSpeedControlEffect

var system: ProjectileSystem

func _ready() -> void:
	system = ProjectileSystem.new()
	add_child(system)
	system.theme.trailSizeCurve = preload("./SkillSpeedControlTrailCurve.tres")
	system.theme.trailColorGradient = preload("./SkillSpeedControlTrailGradient.tres")
	system.theme.trailTimeSizeCurve = preload("./SkillSpeedControlTrailTimeCurve.tres")
	system.theme.trailTimeColorGradient = preload("./SkillSpeedControlTrailTimeGradient.tres")

func Play(target: Vector3, projectileCount: int, duration: float = 1.0) -> void:
	var projectileDelay = duration / projectileCount / 4.0
	var def = ProjectileSystem.Definition.new()
	def.arcSelector = func(_index: int) -> float: return randf_range(-1, 1)
	def.travelTimeSelector = func(index: int) -> float: return duration - projectileDelay * index
	await system.play(global_position, global_position + target, def, projectileCount, projectileDelay)
