@tool
extends Node3D
class_name SkillManaDrainEffect

const ProjectileDelay = 0.1

var system: ProjectileSystem

func _ready() -> void:
	system = ProjectileSystem.new()
	add_child(system)
	system.theme.trailSizeCurve = preload("./SkillManaDrainTrailCurve.tres")
	system.theme.trailColorGradient = preload("./SkillManaDrainTrailGradient.tres")
	system.theme.trailTimeSizeCurve = preload("./SkillManaDrainTrailTimeCurve.tres")
	system.theme.trailTimeColorGradient = preload("./SkillManaDrainTrailTimeGradient.tres")

func Play(target: Vector3, projectileCount: float, duration: float = 0.2) -> void:
	var def = ProjectileSystem.Definition.new()
	def.travelTime = duration
	def.arcSelector = func(_index: int) -> float: return randf_range(-1, 1)
	await system.play(global_position, global_position + target, def, int(projectileCount), ProjectileDelay)
