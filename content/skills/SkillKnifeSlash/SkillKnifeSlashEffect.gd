@tool
extends Node3D
class_name SkillKnifeSlashEffect

@export_tool_button("Play")
var hello_world = func() -> void:
	Play()

var duration: float = 0.3

var system: ProjectileSystem

func _init() -> void:
	scale = Vector3(1.7,1.7,1.7)

func _ready() -> void:
	system = ProjectileSystem.new()
	add_child(system)
	system.theme.trailSizeCurve = preload("res://content/effects/NeverkinClawTrail/NeverkinClawTrailCurve.tres")
	system.theme.trailColorGradient = preload("res://content/effects/NeverkinClawTrail/NeverkinClawTrailGradient.tres")
	system.theme.trailTimeSizeCurve = preload("res://content/effects/NeverkinClawTrail/NeverkinClawTrailTimeCurve.tres")
	system.theme.trailTimeColorGradient = preload("res://content/effects/NeverkinClawTrail/NeverkinClawTrailTimeGradient.tres")

func Play() -> void:
	#createSwipeTrail(Vector3(-0.3, 0, -0.33), Vector3(0.2, 0, 0.2), 0.1)
	#await get_tree().create_timer(0.01).timeout
	createSwipeTrail(Vector3(-0.22, 0, -0.4), Vector3(0.28, 0, 0.13), 0.1)
	#await get_tree().create_timer(0.01).timeout
	#createSwipeTrail(Vector3(-0.14, 0, -0.47), Vector3(0.36, 0, 0.06), 0.1)

func createSwipeTrail(from: Vector3, to: Vector3, arc: float) -> void:
	var def = ProjectileSystem.Definition.new()
	def.width = 0.06 * scale.x
	def.arc = arc * scale.x
	def.travelTime = duration
	def.lingerTime = 0.15
	def.tweenEaseType = Tween.EASE_IN_OUT
	def.renderHeight = global_position.y
	system.play(to_global(from), to_global(to), def)
