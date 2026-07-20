@tool
extends Node3D
class_name SkillRailgunShotEffect

var duration: float = 0.3

var system: ProjectileSystem

func _ready() -> void:
	system = ProjectileSystem.new()
	add_child(system)
	system.theme.trailSizeCurve = preload("res://content/effects/KineticWeaponTrail/KineticWeaponTrailCurve.tres")
	system.theme.trailColorGradient = preload("res://content/effects/KineticWeaponTrail/KineticWeaponTrailGradient.tres")
	system.theme.trailTimeSizeCurve = preload("res://content/effects/KineticWeaponTrail/KineticWeaponTrailTimeCurve.tres")
	system.theme.trailTimeColorGradient = preload("res://content/effects/KineticWeaponTrail/KineticWeaponTrailTimeGradient.tres")

func Play(target: Vector3) -> void:
	var def = ProjectileSystem.Definition.new()
	def.width = 0.08
	def.travelTime = duration
	def.lingerTime = 1.25
	system.play(global_position, global_position + target, def)
