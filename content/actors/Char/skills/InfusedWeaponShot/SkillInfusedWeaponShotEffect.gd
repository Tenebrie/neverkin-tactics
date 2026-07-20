@tool
extends Node3D
class_name SkillInfusedWeaponShotEffect

var infused = false

var system: ProjectileSystem

func _ready() -> void:
	system = ProjectileSystem.new()
	add_child(system)

func Play(target: Vector3, duration: float = 0.2) -> void:
	var theme = ProjectileSystem.ProjectileTheme.new()
	if infused:
		theme.trailSizeCurve = preload("res://content/effects/InfusedWeaponTrail/InfusedWeaponTrailCurve.tres")
		theme.trailColorGradient = preload("res://content/effects/InfusedWeaponTrail/InfusedWeaponTrailGradient.tres")
		theme.trailTimeSizeCurve = preload("res://content/effects/InfusedWeaponTrail/InfusedWeaponTrailTimeCurve.tres")
		theme.trailTimeColorGradient = preload("res://content/effects/InfusedWeaponTrail/InfusedWeaponTrailTimeGradient.tres")
	else:
		theme.trailSizeCurve = preload("res://content/effects/KineticWeaponTrail/KineticWeaponTrailCurve.tres")
		theme.trailColorGradient = preload("res://content/effects/KineticWeaponTrail/KineticWeaponTrailGradient.tres")
		theme.trailTimeSizeCurve = preload("res://content/effects/KineticWeaponTrail/KineticWeaponTrailTimeCurve.tres")
		theme.trailTimeColorGradient = preload("res://content/effects/KineticWeaponTrail/KineticWeaponTrailTimeGradient.tres")
	system.theme = theme

	var def = ProjectileSystem.Definition.new()
	def.travelTime = duration
	system.play(global_position, global_position + target, def)
