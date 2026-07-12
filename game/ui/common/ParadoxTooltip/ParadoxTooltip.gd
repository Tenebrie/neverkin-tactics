extends CanvasLayer
class_name ParadoxTooltip

var isLocked = false

var root: Control
var mainCanvas: CanvasLayer
var backdropCanvas: CanvasLayer

var usesForcedPosition = false
var forcedPosition: Vector2

func _ready() -> void:
	visible = false
	if get_child_count() != 1:
		push_error("ParadoxTooltip must have exactly 1 child with available size")
		return
	root = get_child(0)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED

func _process(_delta: float):
	if isLocked:
		visible = true
	if not visible and not isLocked:
		return

	var firstChild: Control = get_child(0)
	if not isLocked:
		if usesForcedPosition:
			offset = forcedPosition
		else:
			offset = get_viewport().get_mouse_position() - Vector2(firstChild.size.x, firstChild.size.y / 2.0)
		offset.x = clampf(offset.x, 0, get_viewport().get_visible_rect().size.x - firstChild.size.x)
		offset.y = clampf(offset.y, 0, get_viewport().get_visible_rect().size.y - firstChild.size.y)

func lockTooltip():
	if isLocked:
		return
	isLocked = true
	backdropCanvas = CanvasLayer.new()
	backdropCanvas.layer = layer
	var panel = Panel.new()
	backdropCanvas.add_child(panel)
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color(0,0,0, 0.2)
	panel.add_theme_stylebox_override(&"panel", stylebox)
	panel.size = get_viewport().get_visible_rect().size
	panel.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
			unlockTooltip()
	)
	layer += 1
	add_child(backdropCanvas)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_INHERITED

func unlockTooltip():
	isLocked = false
	visible = false
	layer -= 1
	if backdropCanvas:
		backdropCanvas.queue_free()
		backdropCanvas.visible = false
		backdropCanvas = null
	MouseArea3D.updateHoverStates()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("lockParadoxTooltip"):
		lockTooltip()
		get_viewport().set_input_as_handled()

func resizeToContent() -> void:
	if root == null:
		return
	_forceLayout(root)
	_invalidateMins(root)
	root.reset_size()

static func _forceLayout(node: Node) -> void:
	if node is Container:
		node.notification(Container.NOTIFICATION_SORT_CHILDREN)
	for child in node.get_children():
		_forceLayout(child)

static func _invalidateMins(node: Node) -> void:
	if node is Control:
		node.update_minimum_size()
	for child in node.get_children():
		_invalidateMins(child)
