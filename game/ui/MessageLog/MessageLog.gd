class_name MessageLog extends Control

static var instance: MessageLog

func _ready() -> void:
	instance = self
	var container := $%Messages
	while container.get_child_count() > 0:
		var child := container.get_child(0)
		child.queue_free()
		container.remove_child(child)

func printMessage(message: String) -> void:
	var container: VBoxContainer = $%Messages
	while container.get_child_count() > 16:
		var child := container.get_child(0)
		child.queue_free()
		container.remove_child(child)

	var node := Label.new()
	node.add_theme_font_size_override("font_size", 22)
	node.text = message
	container.add_child(node)
	await get_tree().create_timer(8).timeout
	if not is_instance_valid(node):
		return
	create_tween().tween_property(node, ^"modulate", Color.from_hsv(0, 0, 1, 0.0), 0.5)
	await get_tree().create_timer(0.5).timeout
	node.queue_free()

static func PrintMessage(message: String) -> void:
	instance.printMessage(message)
