class_name CameraMotionBlur
extends CanvasLayer

@export var strength = 0.5

var blurMaterial: ShaderMaterial
var blurRect: ColorRect
var lastPosition: Vector3

@onready var camera: Camera3D = get_parent()

func _ready() -> void:
	layer = -1
	blurMaterial = ShaderMaterial.new()
	blurMaterial.shader = preload("./MotionBlur.gdshader")
	blurRect = ColorRect.new()
	blurRect.material = blurMaterial
	blurRect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	blurRect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(blurRect)
	lastPosition = camera.position

func _process(delta: float) -> void:
	if delta <= 0.0:
		return
	var worldDelta = camera.position - lastPosition
	lastPosition = camera.position

	var viewportSize = get_viewport().get_visible_rect().size
	var velocity = Vector2.ZERO
	if worldDelta.length() < camera.size:
		velocity = Vector2(
			-worldDelta.dot(camera.global_transform.basis.x) / (camera.size * viewportSize.aspect()),
			worldDelta.dot(camera.global_transform.basis.y) / camera.size
		) * (strength / (delta * 120.0))
		velocity = velocity.limit_length(0.04)

	if velocity.length() * viewportSize.y < 2.0:
		velocity = Vector2.ZERO

	blurRect.visible = velocity != Vector2.ZERO
	blurMaterial.set_shader_parameter("velocity", velocity)
