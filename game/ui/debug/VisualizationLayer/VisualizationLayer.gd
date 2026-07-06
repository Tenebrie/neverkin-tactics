extends Control
class_name VisualizationLayer

func _ready():
	visible = false

	var timer = Timer.new()
	timer.wait_time = 0.1
	timer.timeout.connect(updateRender)
	add_child(timer)
	timer.start()

func updateRender():
	if not visible:
		return
	for child in get_children():
		if child is VisualizationLayerTextCell:
			child.visible = false
			textCellPool.push_back(child)

func _unhandled_input(inputEvent: InputEvent) -> void:
	if inputEvent is InputEventKey keyEvent and inputEvent.is_pressed() and not inputEvent.is_echo():
		var code = keyEvent.keycode - KEY_KP_0
		if code < 0 or code > 9:
			return
		enableLayer(code)

func enableLayer(index: int) -> void:
	var allLayers = get_tree().root.get_children().filter(func(node):
		return node is VisualizationLayer
	)
	for i in allLayers.size():
		var layer = allLayers[i] as VisualizationLayer
		if layer != self:
			continue

		if index == i and not visible:
			updateRender()
			show()
		else:
			hide()

var textCellPool: Array[VisualizationLayerTextCell]

func setPointValue(value: float, worldPoint: Vector3) -> VisualizationLayerTextCell:
	var text = "%.2f"%value if value < 0 else "+%.2f"%value
	var cell = setPointText(text, worldPoint)
	#var cell = setPointText("", worldPoint)
	cell.color = Color(clampf(-value / 3.0, 0, 1), clampf(value / 3.0, 0, 1), 0.0)
	return cell

func setPointText(value: String, worldPoint: Vector3) -> VisualizationLayerTextCell:
	var textCell: VisualizationLayerTextCell
	if not textCellPool.is_empty():
		textCell = textCellPool.pop_front()
	else:
		textCell = Asset.Instantiate(VisualizationLayerTextCell)
	textCell.SetMessage(value)
	textCell.SetPosition(worldPoint)
	if textCell.is_inside_tree():
		textCell.visible = true
	else:
		add_child(textCell)
	return textCell
