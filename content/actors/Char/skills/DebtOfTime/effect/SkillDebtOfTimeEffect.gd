@tool
extends Node3D
class_name SkillDebtOfTimeEffect

var system: ProjectileSystem

func _ready() -> void:
	system = ProjectileSystem.new()
	add_child(system)
	system.theme.trailSizeCurve = preload("./SkillDebtOfTimeTrailCurve.tres")
	system.theme.trailColorGradient = preload("./SkillDebtOfTimeTrailGradient.tres")
	system.theme.trailTimeSizeCurve = preload("./SkillDebtOfTimeTrailTimeCurve.tres")
	system.theme.trailTimeColorGradient = preload("./SkillDebtOfTimeTrailTimeGradient.tres")

func Play(target: Vector3, duration: float = 0.2) -> void:
	var def = ProjectileSystem.Definition.new()
	def.travelTime = duration
	def.tweenEaseType = Tween.EASE_IN
	def.tweenTransitionType = Tween.TRANS_QUAD
	def.arcSelector = func(_index: int) -> float: return randf_range(-1, 1)
	await system.play(global_position, target, def, 5, 0.02)
